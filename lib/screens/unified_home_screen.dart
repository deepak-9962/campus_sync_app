import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/dashboard_feature.dart';
import '../helpers/dashboard_feature_helper.dart';
import '../services/auth_service.dart';
import '../services/hod_service.dart';
import '../services/user_session_service.dart';
import 'auth_screen.dart';
import 'profile_settings_screen.dart';

/// Unified HomeScreen that serves as the main dashboard for all user roles
class HomeScreen extends StatefulWidget {
  final String userName;
  final String? department; // Made optional for role-based access
  final int? semester; // Made optional for role-based access

  const HomeScreen({
    super.key,
    required this.userName,
    this.department,
    this.semester,
  });

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isLoadingRole = true;
  String _userRole = 'student';
  String? _assignedDepartment;
  List<DashboardFeature> _features = [];
  final AuthService _authService = AuthService();
  final HODService _hodService = HODService();

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadUserDataAndFeatures();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
  }

  Future<void> _loadUserDataAndFeatures() async {
    try {
      // Get user role information
      final role = await _authService.getUserRole();
      final hodInfo = await _hodService.getUserRoleInfo();

      // Determine effective role: treat admins with an assigned department as HOD too
      final bool isHOD =
          hodInfo['isHOD'] == true ||
          (role.toLowerCase() == 'admin' &&
              (hodInfo['assignedDepartment'] != null &&
                  (hodInfo['assignedDepartment'] as String).isNotEmpty));
      final String effectiveRole = isHOD ? 'hod' : role.toLowerCase();

      setState(() {
        _userRole = effectiveRole;
        _assignedDepartment = hodInfo['assignedDepartment'];
        _isLoadingRole = false;
      });

      // Load features based on the role
      _loadFeatures();
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoadingRole = false;
      });
      // Load default student features on error
      _loadFeatures();
    }
  }

  void _loadFeatures() {
    final features = DashboardFeatureHelper.getDashboardFeatures(
      role: _userRole,
      context: context,
      userName: widget.userName,
      department:
          _userRole == 'hod'
              ? (_assignedDepartment ?? '')
              : (widget.department ??
                  ''), // Ensure department is non-null string
      semester:
          _userRole == 'hod'
              ? 1 // HOD dashboard might not be semester-specific, or default to 1
              : (widget.semester ?? 1), // Use assignedDepartment for HOD
      assignedDepartment: _assignedDepartment,
    );

    setState(() {
      _features = features;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0.5,
        centerTitle: true,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school, color: colorScheme.primary, size: 24),
            const SizedBox(width: 8),
            Text(
              'Campus Sync',
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person, color: colorScheme.onSurface),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileSettingsScreen(),
                  ),
                ),
          ),
        ],
      ),
      drawer: _buildSimpleDrawer(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadUserDataAndFeatures();
          },
          child:
              _isLoadingRole
                  ? _buildLoadingState(colorScheme)
                  : _buildDashboard(colorScheme, textTheme),
        ),
      ),
    );
  }

  Widget _buildSimpleDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  widget.userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DashboardFeatureHelper.getRoleDisplayName(_userRole),
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileSettingsScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              Navigator.pop(context);
              try {
                await Supabase.instance.client.auth.signOut();
                UserSessionService().clearSession();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const AuthScreen()),
                    (route) => false,
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error logging out: $e')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your dashboard...',
            style: TextStyle(color: colorScheme.onBackground, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(ColorScheme colorScheme, TextTheme textTheme) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Welcome header
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _animationController,
            child: _buildWelcomeHeader(colorScheme, textTheme),
          ),
        ),

        // Dashboard grid
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 1.0,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index >= _features.length) return null;

              return AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  final delay = index * 0.1;
                  final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: Interval(
                        delay,
                        delay + 0.6,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                  );

                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(animation),
                      child: _buildFeatureCard(_features[index], colorScheme),
                    ),
                  );
                },
              );
            }, childCount: _features.length),
          ),
        ),

        // Footer space
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  Widget _buildWelcomeHeader(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                DashboardFeatureHelper.getRoleIcon(_userRole),
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back!',
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      widget.userName,
                      style: textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              DashboardFeatureHelper.getRoleDisplayName(_userRole),
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_assignedDepartment != null) ...[
            const SizedBox(height: 8),
            Text(
              'Department: $_assignedDepartment',
              style: textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              '${widget.department} • Semester ${widget.semester}',
              style: textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureCard(DashboardFeature feature, ColorScheme colorScheme) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: feature.isEnabled ? feature.onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: colorScheme.surface,
            border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (feature.color ?? colorScheme.primary).withOpacity(
                    0.1,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  feature.icon,
                  size: 32,
                  color: feature.color ?? colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                feature.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color:
                      feature.isEnabled
                          ? colorScheme.onSurface
                          : colorScheme.onSurface.withOpacity(0.5),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (feature.subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  feature.subtitle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        feature.isEnabled
                            ? colorScheme.onSurface.withOpacity(0.7)
                            : colorScheme.onSurface.withOpacity(0.3),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
