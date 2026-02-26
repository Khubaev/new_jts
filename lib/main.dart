import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/requests/screens/requests_list_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/requests_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RequestsProvider()),
      ],
      child: MaterialApp(
        title: 'Учёт заявок',
        theme: AppTheme.light,
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.isAuthenticated) {
              return const RequestsListScreen();
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
