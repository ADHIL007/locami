import 'package:flutter/material.dart';
import 'package:locami/theme/app_text_style.dart';
import 'package:locami/theme/them_provider.dart';

class DownloadStreetnames extends StatefulWidget {
  const DownloadStreetnames({Key? key}) : super(key: key);

  @override
  _DownloadStreetnamesState createState() => _DownloadStreetnamesState();
}

class _DownloadStreetnamesState extends State<DownloadStreetnames> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Setting up your initial setups',

                  style: AppTextStyles.question.copyWith(
                    color: customColors().textSecondary,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: LinearProgressIndicator(),
          ),
        ],
      ),
    );
  }
}
