import 'package:auto_route/auto_route.dart';

import '../app_route.gr.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthGuard extends AutoRouteGuard {
  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    bool loggedIn = pref.getBool('logged_in') ?? false;
    if (loggedIn) {
      router.removeLast();
      resolver.next(true);
    } else {
      // router.removeLast();
      router.replace(SignInWidget(onResult: (result) async {
        if (result == true) {
          resolver.next(true);
          // remove login screen from route
          router.removeLast();
        }
        // else stay at login route
      }));
    }
  }
}