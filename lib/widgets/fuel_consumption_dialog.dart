// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

class FuelConsumptionDialog extends StatefulWidget {
  const FuelConsumptionDialog({super.key});

  @override
  State<FuelConsumptionDialog> createState() => _FuelConsumptionDialogState();
}

class _FuelConsumptionDialogState extends State<FuelConsumptionDialog> {
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _fuelController = TextEditingController();

  bool _isKmUnit = true; // true = km, false = miles
  bool _isLiterUnit = true; // true = liter, false = gallon

  double _consumption = 0.0;
  String _consumptionText = '';

  @override
  void dispose() {
    _distanceController.dispose();
    _fuelController.dispose();
    super.dispose();
  }

  void _calculateConsumption() {
    final double distance = double.tryParse(_distanceController.text) ?? 0;
    final double fuel = double.tryParse(_fuelController.text) ?? 0;

    if (distance <= 0 || fuel <= 0) {
      setState(() {
        _consumption = 0.0;
        _consumptionText = AppLocalizations.enterValidValues;
      });
      return;
    }

    // Alapértelmezett számítás: L/100km
    double baseConsumption = (fuel / distance) * 100;

    // Átváltások kezelése
    if (!_isKmUnit && _isLiterUnit) {
      // Miles és liter -> L/100km
      baseConsumption = (fuel / (distance * 1.60934)) * 100;
    } else if (_isKmUnit && !_isLiterUnit) {
      // Km és gallon -> L/100km
      baseConsumption = ((fuel * 3.78541) / distance) * 100;
    } else if (!_isKmUnit && !_isLiterUnit) {
      // Miles és gallon -> MPG majd átváltás L/100km-re
      double mpg = distance / fuel;
      baseConsumption = 235.214 / mpg; // MPG -> L/100km átváltás
    }

    setState(() {
      _consumption = baseConsumption;
      _consumptionText = _getConsumptionText(baseConsumption);
    });
  }

  String _getConsumptionText(double consumption) {
    if (_isKmUnit && _isLiterUnit) {
      return '${consumption.toStringAsFixed(2)} L/100km';
    } else if (!_isKmUnit && !_isLiterUnit) {
      // MPG kijelzés
      double mpg = 235.214 / consumption;
      return '${mpg.toStringAsFixed(2)} MPG\n(${consumption.toStringAsFixed(2)} L/100km)';
    } else if (_isKmUnit && !_isLiterUnit) {
      // Gallon/100km
      double gallonPer100km = consumption / 3.78541;
      return '${gallonPer100km.toStringAsFixed(2)} Gal/100km\n(${consumption.toStringAsFixed(2)} L/100km)';
    } else {
      // Miles és liter
      return '${consumption.toStringAsFixed(2)} L/100km';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.local_gas_station, color: Colors.red, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.fuelConsumption,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Unit selectors
              Row(
                children: [
                  Expanded(
                    child: _buildUnitSelector(
                      AppLocalizations.distance,
                      _isKmUnit,
                      AppLocalizations.kilometers,
                      AppLocalizations.miles,
                      (value) => setState(() => _isKmUnit = value),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildUnitSelector(
                      AppLocalizations.fuel,
                      _isLiterUnit,
                      AppLocalizations.liters,
                      AppLocalizations.gallons,
                      (value) => setState(() => _isLiterUnit = value),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Input fields
              _buildInputField(
                AppLocalizations.distanceTraveled,
                _distanceController,
                _isKmUnit
                    ? AppLocalizations.kilometers
                    : AppLocalizations.miles,
              ),

              SizedBox(height: 16),

              _buildInputField(
                AppLocalizations.fuelConsumed,
                _fuelController,
                _isLiterUnit
                    ? AppLocalizations.liters
                    : AppLocalizations.gallons,
              ),

              SizedBox(height: 20),

              // Calculate button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _calculateConsumption,
                  icon: Icon(Icons.calculate),
                  label: Text(AppLocalizations.calculate),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Result display
              if (_consumption > 0)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.eco, color: Colors.green, size: 32),
                      SizedBox(height: 8),
                      Text(
                        AppLocalizations.consumption,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _consumptionText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

              if (_consumptionText.isNotEmpty && _consumption == 0)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Text(
                    _consumptionText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 16,
                    ),
                  ),
                ),

              // Extra padding a keyboard számára
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnitSelector(
    String title,
    bool currentValue,
    String option1,
    String option2,
    Function(bool) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(true),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: currentValue ? Colors.red : Colors.transparent,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                    ),
                    child: Text(
                      option1,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight:
                            currentValue ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(false),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: !currentValue ? Colors.red : Colors.transparent,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: Text(
                      option2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight:
                            !currentValue ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(
      String label, TextEditingController controller, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[800],
            suffixText: unit,
            suffixStyle: TextStyle(color: Colors.white70),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}

