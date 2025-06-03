// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../providers/speed_provider.dart';
import '../providers/language_provider.dart';
import '../localization/app_localizations.dart';
import '../speed_meter/widgets/Messages/help_dialog.dart';
import './fuel_consumption_dialog.dart'; // ÚJ IMPORT

class SettingsDialog extends StatelessWidget {
  final SpeedProvider speedProvider;
  final LanguageProvider languageProvider;

  const SettingsDialog({
    super.key,
    required this.speedProvider,
    required this.languageProvider,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return StatefulBuilder(
      builder: (context, setState) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: screenHeight * 0.1,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: screenHeight * 0.8,
              maxWidth: screenWidth * 0.9,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey[900]!,
                  Colors.black,
                  Colors.grey[850]!,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.red.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.1),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header - kompaktabb
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade600, Colors.red.shade800],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.settings,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppLocalizations.settings,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content - kompaktabb padding
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Speed Unit Setting
                        _buildCompactSettingTile(
                          icon: Icons.speed,
                          title: AppLocalizations.speedUnit,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<bool>(
                                dropdownColor: Colors.grey[800],
                                value: speedProvider.isKmh,
                                isDense: true,
                                onChanged: (bool? newValue) {
                                  if (newValue != null) {
                                    speedProvider.setSpeedUnit(newValue);
                                    setState(() {});
                                  }
                                },
                                items: [
                                  DropdownMenuItem(
                                    value: true,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.speed,
                                            color: Colors.red, size: 14),
                                        SizedBox(width: 6),
                                        Text('km/h',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14)),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: false,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.speed,
                                            color: Colors.red, size: 14),
                                        SizedBox(width: 6),
                                        Text('mph',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 12),

                        // Language Setting
                        _buildCompactSettingTile(
                          icon: Icons.language,
                          title: AppLocalizations.language,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                dropdownColor: Colors.grey[800],
                                value: languageProvider.languageCode,
                                isDense: true,
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    languageProvider.setLanguage(newValue);
                                    setState(() {});
                                  }
                                },
                                items: [
                                  DropdownMenuItem(
                                    value: 'hu',
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('🇭🇺',
                                            style: TextStyle(fontSize: 14)),
                                        SizedBox(width: 6),
                                        Text(AppLocalizations.hungarian,
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14)),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'en',
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('🇺🇸',
                                            style: TextStyle(fontSize: 14)),
                                        SizedBox(width: 6),
                                        Text(AppLocalizations.english,
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14)),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'de',
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('🇩🇪',
                                            style: TextStyle(fontSize: 14)),
                                        SizedBox(width: 6),
                                        Text(AppLocalizations.german,
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 12),

                        // Fuel Consumption Setting - ÚJ FUNKCIÓ
                        _buildCompactSettingTile(
                          icon: Icons.local_gas_station,
                          title: AppLocalizations.fuelConsumption,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context)
                                    .pop(); // Bezárjuk az aktuális dialógust
                                _showFuelConsumptionDialog(context);
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.calculate,
                                      color: Colors.red, size: 14),
                                  SizedBox(width: 6),
                                  Text(AppLocalizations.openFuelCalculator,
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 14)),
                                  Icon(Icons.arrow_forward_ios,
                                      color: Colors.grey, size: 12),
                                ],
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 12),

                        // Information Button - ÁTMOZGATVA IDE AZ ALJÁRA
                        _buildCompactSettingTile(
                          icon: Icons.info_outline,
                          title: AppLocalizations.information,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.red.shade600,
                                  Colors.red.shade700
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  Navigator.pop(context);
                                  showHelpDialog(context);
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.help_outline,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        AppLocalizations.help, // LOKALIZÁLVA
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactSettingTile({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850]?.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[700]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: Colors.red,
              size: 16,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: 8),
          child,
        ],
      ),
    );
  }

  void _showFuelConsumptionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => FuelConsumptionDialog(),
    );
  }
}
