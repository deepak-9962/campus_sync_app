// Supabase Edge Function: process-scheduled-reports
// Processes scheduled reports and sends emails to recipients
// 
// Deploy: supabase functions deploy process-scheduled-reports
// Test: supabase functions invoke process-scheduled-reports --body '{"frequency": "daily"}'

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface ScheduledReport {
  id: string;
  report_type: string;
  department: string;
  semester: number | null;
  section: string | null;
  recipients: string[];
  frequency: string;
  scheduled_hour: number;
  scheduled_minute: number;
  enabled: boolean;
}

interface EmailPayload {
  to: string[];
  subject: string;
  html: string;
  attachmentUrl?: string;
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Initialize Supabase client with service role key
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Parse request body
    const body = await req.json().catch(() => ({}));
    const frequencyFilter = body.frequency as string | undefined;

    console.log(`Processing scheduled reports${frequencyFilter ? ` (frequency: ${frequencyFilter})` : ""}`);

    // Get due reports
    let query = supabase
      .from("scheduled_reports")
      .select("*")
      .eq("enabled", true)
      .lte("next_run", new Date().toISOString());

    if (frequencyFilter) {
      query = query.eq("frequency", frequencyFilter);
    }

    const { data: dueReports, error: fetchError } = await query;

    if (fetchError) {
      throw new Error(`Failed to fetch due reports: ${fetchError.message}`);
    }

    if (!dueReports || dueReports.length === 0) {
      console.log("No reports due for processing");
      return new Response(
        JSON.stringify({ message: "No reports due", processed: 0 }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    console.log(`Found ${dueReports.length} reports to process`);

    const results: Array<{ id: string; status: string; error?: string }> = [];

    for (const report of dueReports as ScheduledReport[]) {
      try {
        console.log(`Processing report: ${report.report_type} for ${report.department}`);

        // Generate report data
        const reportData = await generateReportData(supabase, report);

        // Generate HTML report
        const htmlReport = generateHtmlReport(report, reportData);

        // Send emails to recipients
        if (report.recipients && report.recipients.length > 0) {
          await sendReportEmail(supabase, {
            to: report.recipients,
            subject: getReportSubject(report),
            html: htmlReport,
          });
        }

        // Log successful generation
        await supabase.from("report_logs").insert({
          report_type: report.report_type,
          department: report.department,
          semester: report.semester,
          generated_by: "system",
          status: "success",
        });

        // Update next run time
        await supabase.rpc("update_next_run", { schedule_id: report.id });

        results.push({ id: report.id, status: "success" });
        console.log(`Successfully processed report: ${report.id}`);
      } catch (error) {
        const errorMessage = error instanceof Error ? error.message : String(error);
        console.error(`Error processing report ${report.id}:`, error);

        // Log failure
        await supabase.from("report_logs").insert({
          report_type: report.report_type,
          department: report.department,
          semester: report.semester,
          generated_by: "system",
          status: "failed",
          error_message: errorMessage,
        });

        results.push({ id: report.id, status: "failed", error: errorMessage });
      }
    }

    return new Response(
      JSON.stringify({
        message: "Reports processed",
        processed: results.length,
        results,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    console.error("Edge function error:", error);
    return new Response(
      JSON.stringify({ error: errorMessage }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
  }
});

// Generate report data based on type
async function generateReportData(supabase: any, report: ScheduledReport): Promise<any> {
  const today = new Date().toISOString().split("T")[0];

  switch (report.report_type) {
    case "dailyAttendance":
      return await getDailyAttendanceData(supabase, report, today);

    case "weeklyLowAttendance":
      return await getLowAttendanceData(supabase, report);

    case "monthlyAnalytics":
      return await getMonthlyAnalyticsData(supabase, report);

    case "semesterConsolidation":
      return await getSemesterConsolidationData(supabase, report);

    default:
      throw new Error(`Unknown report type: ${report.report_type}`);
  }
}

async function getDailyAttendanceData(supabase: any, report: ScheduledReport, date: string) {
  // Get attendance for today
  let query = supabase
    .from("attendance")
    .select(`
      registration_no,
      is_present,
      period_number,
      students!inner(student_name, section, semester, department)
    `)
    .eq("date", date)
    .ilike("students.department", `%${report.department}%`);

  if (report.semester) {
    query = query.eq("students.semester", report.semester);
  }

  const { data, error } = await query;
  if (error) throw error;

  // Aggregate data
  const studentMap = new Map();
  for (const record of data || []) {
    const regNo = record.registration_no;
    if (!studentMap.has(regNo)) {
      studentMap.set(regNo, {
        registration_no: regNo,
        student_name: record.students.student_name,
        section: record.students.section,
        present_periods: 0,
        total_periods: 0,
      });
    }
    const student = studentMap.get(regNo);
    student.total_periods++;
    if (record.is_present) student.present_periods++;
  }

  const students = Array.from(studentMap.values());
  const totalStudents = students.length;
  const presentCount = students.filter((s) => s.present_periods > 0).length;

  return {
    date,
    department: report.department,
    semester: report.semester,
    totalStudents,
    presentCount,
    absentCount: totalStudents - presentCount,
    percentage: totalStudents > 0 ? ((presentCount / totalStudents) * 100).toFixed(1) : "0",
    students,
  };
}

async function getLowAttendanceData(supabase: any, report: ScheduledReport) {
  let query = supabase
    .from("overall_attendance_summary")
    .select("*")
    .ilike("department", `%${report.department}%`)
    .lt("overall_percentage", 75)
    .order("overall_percentage");

  if (report.semester) {
    query = query.eq("semester", report.semester);
  }

  const { data, error } = await query;
  if (error) throw error;

  // Get student names
  const students = [];
  for (const record of data || []) {
    const { data: student } = await supabase
      .from("students")
      .select("student_name")
      .eq("registration_no", record.registration_no)
      .single();

    students.push({
      ...record,
      student_name: student?.student_name || "Unknown",
    });
  }

  return {
    department: report.department,
    semester: report.semester,
    threshold: 75,
    totalLowAttendance: students.length,
    students,
  };
}

async function getMonthlyAnalyticsData(supabase: any, report: ScheduledReport) {
  const now = new Date();
  const monthStart = new Date(now.getFullYear(), now.getMonth(), 1).toISOString().split("T")[0];
  const monthEnd = new Date(now.getFullYear(), now.getMonth() + 1, 0).toISOString().split("T")[0];

  let query = supabase
    .from("overall_attendance_summary")
    .select("overall_percentage")
    .ilike("department", `%${report.department}%`);

  if (report.semester) {
    query = query.eq("semester", report.semester);
  }

  const { data, error } = await query;
  if (error) throw error;

  const percentages = (data || []).map((r: any) => r.overall_percentage);
  const total = percentages.length;

  return {
    department: report.department,
    semester: report.semester,
    month: now.toLocaleString("default", { month: "long", year: "numeric" }),
    monthStart,
    monthEnd,
    totalStudents: total,
    avgPercentage: total > 0 ? (percentages.reduce((a: number, b: number) => a + b, 0) / total).toFixed(1) : "0",
    above90: percentages.filter((p: number) => p >= 90).length,
    between75And90: percentages.filter((p: number) => p >= 75 && p < 90).length,
    between60And75: percentages.filter((p: number) => p >= 60 && p < 75).length,
    below60: percentages.filter((p: number) => p < 60).length,
  };
}

async function getSemesterConsolidationData(supabase: any, report: ScheduledReport) {
  let query = supabase
    .from("overall_attendance_summary")
    .select("*")
    .ilike("department", `%${report.department}%`)
    .order("registration_no");

  if (report.semester) {
    query = query.eq("semester", report.semester);
  }

  if (report.section) {
    query = query.eq("section", report.section);
  }

  const { data, error } = await query;
  if (error) throw error;

  // Get student names
  const students = [];
  for (const record of data || []) {
    const { data: student } = await supabase
      .from("students")
      .select("student_name")
      .eq("registration_no", record.registration_no)
      .single();

    students.push({
      ...record,
      student_name: student?.student_name || "Unknown",
      eligible: record.overall_percentage >= 75,
    });
  }

  const eligible = students.filter((s) => s.eligible).length;

  return {
    department: report.department,
    semester: report.semester,
    section: report.section,
    academicYear: getAcademicYear(),
    totalStudents: students.length,
    eligible,
    notEligible: students.length - eligible,
    students,
  };
}

// Generate HTML report
function generateHtmlReport(report: ScheduledReport, data: any): string {
  const styles = `
    <style>
      body { font-family: Arial, sans-serif; margin: 20px; color: #333; }
      .header { background: #1976D2; color: white; padding: 20px; border-radius: 8px 8px 0 0; }
      .header h1 { margin: 0; font-size: 24px; }
      .header p { margin: 5px 0 0; opacity: 0.9; }
      .content { padding: 20px; border: 1px solid #ddd; border-top: none; border-radius: 0 0 8px 8px; }
      .summary { display: flex; gap: 20px; flex-wrap: wrap; margin-bottom: 20px; }
      .stat-card { background: #f5f5f5; padding: 15px; border-radius: 8px; text-align: center; min-width: 100px; }
      .stat-value { font-size: 28px; font-weight: bold; color: #1976D2; }
      .stat-label { font-size: 12px; color: #666; margin-top: 5px; }
      .alert { background: #fff3cd; border: 1px solid #ffc107; padding: 15px; border-radius: 8px; margin-bottom: 20px; }
      .alert.danger { background: #f8d7da; border-color: #f5c6cb; }
      table { width: 100%; border-collapse: collapse; margin-top: 20px; }
      th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
      th { background: #f5f5f5; font-weight: 600; }
      tr:hover { background: #f9f9f9; }
      .status-good { color: #28a745; }
      .status-warning { color: #ffc107; }
      .status-danger { color: #dc3545; }
      .footer { margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd; font-size: 12px; color: #666; }
    </style>
  `;

  let content = "";

  switch (report.report_type) {
    case "dailyAttendance":
      content = generateDailyAttendanceHtml(data);
      break;
    case "weeklyLowAttendance":
      content = generateLowAttendanceHtml(data);
      break;
    case "monthlyAnalytics":
      content = generateMonthlyAnalyticsHtml(data);
      break;
    case "semesterConsolidation":
      content = generateSemesterConsolidationHtml(data);
      break;
  }

  return `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <title>${getReportTitle(report)}</title>
      ${styles}
    </head>
    <body>
      <div class="header">
        <h1>Campus Sync</h1>
        <p>${getReportTitle(report)}</p>
      </div>
      <div class="content">
        ${content}
      </div>
      <div class="footer">
        <p>This is an automated report from Campus Sync. Generated on ${new Date().toLocaleString()}.</p>
      </div>
    </body>
    </html>
  `;
}

function generateDailyAttendanceHtml(data: any): string {
  return `
    <h2>Daily Attendance Summary - ${data.date}</h2>
    <p><strong>Department:</strong> ${data.department}</p>
    ${data.semester ? `<p><strong>Semester:</strong> ${data.semester}</p>` : ""}
    
    <div class="summary">
      <div class="stat-card">
        <div class="stat-value">${data.totalStudents}</div>
        <div class="stat-label">Total Students</div>
      </div>
      <div class="stat-card">
        <div class="stat-value" style="color: #28a745">${data.presentCount}</div>
        <div class="stat-label">Present</div>
      </div>
      <div class="stat-card">
        <div class="stat-value" style="color: #dc3545">${data.absentCount}</div>
        <div class="stat-label">Absent</div>
      </div>
      <div class="stat-card">
        <div class="stat-value">${data.percentage}%</div>
        <div class="stat-label">Attendance</div>
      </div>
    </div>
    
    <h3>Student Details</h3>
    <table>
      <thead>
        <tr>
          <th>Reg. No.</th>
          <th>Name</th>
          <th>Section</th>
          <th>Periods Present</th>
          <th>Status</th>
        </tr>
      </thead>
      <tbody>
        ${data.students.map((s: any) => `
          <tr>
            <td>${s.registration_no}</td>
            <td>${s.student_name}</td>
            <td>${s.section || "-"}</td>
            <td>${s.present_periods}/${s.total_periods}</td>
            <td class="${s.present_periods > 0 ? "status-good" : "status-danger"}">
              ${s.present_periods > 0 ? "Present" : "Absent"}
            </td>
          </tr>
        `).join("")}
      </tbody>
    </table>
  `;
}

function generateLowAttendanceHtml(data: any): string {
  return `
    <h2>Weekly Low Attendance Report</h2>
    <p><strong>Department:</strong> ${data.department}</p>
    ${data.semester ? `<p><strong>Semester:</strong> ${data.semester}</p>` : ""}
    
    <div class="alert danger">
      <strong>⚠️ Attention Required:</strong> ${data.totalLowAttendance} students have attendance below ${data.threshold}%
    </div>
    
    <table>
      <thead>
        <tr>
          <th>Reg. No.</th>
          <th>Name</th>
          <th>Semester</th>
          <th>Section</th>
          <th>Total Periods</th>
          <th>Attended</th>
          <th>Percentage</th>
        </tr>
      </thead>
      <tbody>
        ${data.students.map((s: any) => `
          <tr>
            <td>${s.registration_no}</td>
            <td>${s.student_name}</td>
            <td>${s.semester || "-"}</td>
            <td>${s.section || "-"}</td>
            <td>${s.total_periods || 0}</td>
            <td>${s.attended_periods || 0}</td>
            <td class="status-danger">${(s.overall_percentage || 0).toFixed(1)}%</td>
          </tr>
        `).join("")}
      </tbody>
    </table>
  `;
}

function generateMonthlyAnalyticsHtml(data: any): string {
  return `
    <h2>Monthly Analytics Report - ${data.month}</h2>
    <p><strong>Department:</strong> ${data.department}</p>
    ${data.semester ? `<p><strong>Semester:</strong> ${data.semester}</p>` : ""}
    
    <div class="summary">
      <div class="stat-card">
        <div class="stat-value">${data.totalStudents}</div>
        <div class="stat-label">Total Students</div>
      </div>
      <div class="stat-card">
        <div class="stat-value">${data.avgPercentage}%</div>
        <div class="stat-label">Avg Attendance</div>
      </div>
    </div>
    
    <h3>Attendance Distribution</h3>
    <table>
      <thead>
        <tr>
          <th>Category</th>
          <th>Count</th>
          <th>Percentage of Total</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td class="status-good">Excellent (≥90%)</td>
          <td>${data.above90}</td>
          <td>${data.totalStudents > 0 ? ((data.above90 / data.totalStudents) * 100).toFixed(1) : 0}%</td>
        </tr>
        <tr>
          <td class="status-good">Good (75-90%)</td>
          <td>${data.between75And90}</td>
          <td>${data.totalStudents > 0 ? ((data.between75And90 / data.totalStudents) * 100).toFixed(1) : 0}%</td>
        </tr>
        <tr>
          <td class="status-warning">Average (60-75%)</td>
          <td>${data.between60And75}</td>
          <td>${data.totalStudents > 0 ? ((data.between60And75 / data.totalStudents) * 100).toFixed(1) : 0}%</td>
        </tr>
        <tr>
          <td class="status-danger">Poor (<60%)</td>
          <td>${data.below60}</td>
          <td>${data.totalStudents > 0 ? ((data.below60 / data.totalStudents) * 100).toFixed(1) : 0}%</td>
        </tr>
      </tbody>
    </table>
  `;
}

function generateSemesterConsolidationHtml(data: any): string {
  return `
    <h2>Semester Consolidation Report</h2>
    <p><strong>Department:</strong> ${data.department}</p>
    <p><strong>Semester:</strong> ${data.semester || "All"}</p>
    ${data.section ? `<p><strong>Section:</strong> ${data.section}</p>` : ""}
    <p><strong>Academic Year:</strong> ${data.academicYear}</p>
    
    <div class="summary">
      <div class="stat-card">
        <div class="stat-value">${data.totalStudents}</div>
        <div class="stat-label">Total Students</div>
      </div>
      <div class="stat-card">
        <div class="stat-value" style="color: #28a745">${data.eligible}</div>
        <div class="stat-label">Eligible (≥75%)</div>
      </div>
      <div class="stat-card">
        <div class="stat-value" style="color: #dc3545">${data.notEligible}</div>
        <div class="stat-label">Not Eligible (<75%)</div>
      </div>
    </div>
    
    <h3>Student-wise Summary</h3>
    <table>
      <thead>
        <tr>
          <th>S.No</th>
          <th>Reg. No.</th>
          <th>Name</th>
          <th>Section</th>
          <th>Total</th>
          <th>Attended</th>
          <th>Percentage</th>
          <th>Eligible</th>
        </tr>
      </thead>
      <tbody>
        ${data.students.map((s: any, i: number) => `
          <tr>
            <td>${i + 1}</td>
            <td>${s.registration_no}</td>
            <td>${s.student_name}</td>
            <td>${s.section || "-"}</td>
            <td>${s.total_periods || 0}</td>
            <td>${s.attended_periods || 0}</td>
            <td class="${s.eligible ? "status-good" : "status-danger"}">
              ${(s.overall_percentage || 0).toFixed(1)}%
            </td>
            <td class="${s.eligible ? "status-good" : "status-danger"}">
              ${s.eligible ? "Yes" : "No"}
            </td>
          </tr>
        `).join("")}
      </tbody>
    </table>
  `;
}

// Send email via Supabase (queue for external service)
async function sendReportEmail(supabase: any, payload: EmailPayload): Promise<void> {
  // Add emails to queue for processing
  for (const recipient of payload.to) {
    await supabase.from("email_queue").insert({
      recipient,
      subject: payload.subject,
      body: payload.html,
      attachment_url: payload.attachmentUrl,
      status: "pending",
    });
  }

  // Optionally, integrate with email service directly here:
  // - Resend: https://resend.com
  // - SendGrid: https://sendgrid.com
  // - AWS SES: https://aws.amazon.com/ses/

  /*
  // Example with Resend:
  const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");
  if (RESEND_API_KEY) {
    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${RESEND_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: "Campus Sync <reports@campus-sync.app>",
        to: payload.to,
        subject: payload.subject,
        html: payload.html,
      }),
    });

    if (!res.ok) {
      throw new Error(`Email send failed: ${await res.text()}`);
    }
  }
  */

  console.log(`Queued ${payload.to.length} emails for delivery`);
}

// Helper functions
function getReportTitle(report: ScheduledReport): string {
  switch (report.report_type) {
    case "dailyAttendance":
      return "Daily Attendance Report";
    case "weeklyLowAttendance":
      return "Weekly Low Attendance Report";
    case "monthlyAnalytics":
      return "Monthly Analytics Report";
    case "semesterConsolidation":
      return "Semester Consolidation Report";
    default:
      return "Attendance Report";
  }
}

function getReportSubject(report: ScheduledReport): string {
  const date = new Date().toLocaleDateString();
  return `${getReportTitle(report)} - ${report.department} (${date})`;
}

function getAcademicYear(): string {
  const now = new Date();
  const startYear = now.getMonth() >= 5 ? now.getFullYear() : now.getFullYear() - 1;
  return `${startYear}-${(startYear + 1) % 100}`;
}
