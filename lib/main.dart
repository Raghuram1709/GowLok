import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://oagssgyoeqkcctlzusko.supabase.co',
    anonKey: 'sb_publishable_S4sTEQgDfmoMOdmTRF7kfQ_7o7AcpNX',
  );

  runApp(const GowlokApp());
}
