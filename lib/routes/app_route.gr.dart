// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i6;
import 'package:flutter/material.dart' as _i7;
import 'package:insu_tracking/authentication/create_account.dart' as _i1;
import 'package:insu_tracking/authentication/landing.dart' as _i3;
import 'package:insu_tracking/authentication/login_screen.dart' as _i5;
import 'package:insu_tracking/authentication/screens/home.dart' as _i2;
import 'package:insu_tracking/authentication/screens/logout.dart' as _i4;

abstract class $AppRouter extends _i6.RootStackRouter {
  $AppRouter({super.navigatorKey});

  @override
  final Map<String, _i6.PageFactory> pagesMap = {
    CreateAccount4Widget.name: (routeData) {
      return _i6.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i1.CreateAccount4Widget(),
      );
    },
    DashboardWidget.name: (routeData) {
      return _i6.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i2.DashboardWidget(),
      );
    },
    LandingRoute.name: (routeData) {
      return _i6.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i3.LandingPage(),
      );
    },
    LogoutWidget.name: (routeData) {
      return _i6.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i4.LogoutWidget(),
      );
    },
    SignInWidget.name: (routeData) {
      final args = routeData.argsAs<SignInWidgetArgs>();
      return _i6.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i5.SignInWidget(
          key: args.key,
          onResult: args.onResult,
        ),
      );
    },
  };
}

/// generated route for
/// [_i1.CreateAccount4Widget]
class CreateAccount4Widget extends _i6.PageRouteInfo<void> {
  const CreateAccount4Widget({List<_i6.PageRouteInfo>? children})
      : super(
          CreateAccount4Widget.name,
          initialChildren: children,
        );

  static const String name = 'CreateAccount4Widget';

  static const _i6.PageInfo<void> page = _i6.PageInfo<void>(name);
}

/// generated route for
/// [_i2.DashboardWidget]
class DashboardWidget extends _i6.PageRouteInfo<void> {
  const DashboardWidget({List<_i6.PageRouteInfo>? children})
      : super(
          DashboardWidget.name,
          initialChildren: children,
        );

  static const String name = 'DashboardWidget';

  static const _i6.PageInfo<void> page = _i6.PageInfo<void>(name);
}

/// generated route for
/// [_i3.LandingPage]
class LandingRoute extends _i6.PageRouteInfo<void> {
  const LandingRoute({List<_i6.PageRouteInfo>? children})
      : super(
          LandingRoute.name,
          initialChildren: children,
        );

  static const String name = 'LandingRoute';

  static const _i6.PageInfo<void> page = _i6.PageInfo<void>(name);
}

/// generated route for
/// [_i4.LogoutWidget]
class LogoutWidget extends _i6.PageRouteInfo<void> {
  const LogoutWidget({List<_i6.PageRouteInfo>? children})
      : super(
          LogoutWidget.name,
          initialChildren: children,
        );

  static const String name = 'LogoutWidget';

  static const _i6.PageInfo<void> page = _i6.PageInfo<void>(name);
}

/// generated route for
/// [_i5.SignInWidget]
class SignInWidget extends _i6.PageRouteInfo<SignInWidgetArgs> {
  SignInWidget({
    _i7.Key? key,
    required dynamic Function(bool?) onResult,
    List<_i6.PageRouteInfo>? children,
  }) : super(
          SignInWidget.name,
          args: SignInWidgetArgs(
            key: key,
            onResult: onResult,
          ),
          initialChildren: children,
        );

  static const String name = 'SignInWidget';

  static const _i6.PageInfo<SignInWidgetArgs> page =
      _i6.PageInfo<SignInWidgetArgs>(name);
}

class SignInWidgetArgs {
  const SignInWidgetArgs({
    this.key,
    required this.onResult,
  });

  final _i7.Key? key;

  final dynamic Function(bool?) onResult;

  @override
  String toString() {
    return 'SignInWidgetArgs{key: $key, onResult: $onResult}';
  }
}
