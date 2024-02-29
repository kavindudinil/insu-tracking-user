import 'package:auto_route/auto_route.dart';
import 'app_route.gr.dart';
import 'guard/auth_guard.dart';

@AutoRouterConfig()
class AppRouter extends $AppRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: LandingRoute.page, initial: true),
        AutoRoute(page: LogoutWidget.page,guards: [AuthGuard()],),
        AutoRoute(page: DashboardWidget.page,guards: [AuthGuard()]),
        AutoRoute(page: SignInWidget.page),
        AutoRoute(page: CreateAccount4Widget.page),
      ];
}
