import 'package:dyno2/providers/language_provider.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  static final LanguageProvider _languageProvider = LanguageProvider();

  static AppLocalizations of(BuildContext context) {
    return AppLocalizations();
  }

  // Low Speed Warning Message
  static String get lowSpeedWarningMessage {
    if (_languageProvider.isHungarian) {
      return "Legalább 95km/h haladj!";
    } else if (_languageProvider.isGerman) {
      return "Fahre mindestens 95km/h!";
    } else {
      return "Drive at least 95km/h!";
    }
  }

  // Moving Warning Message
  static String get movingWarningMessage {
    if (_languageProvider.isHungarian) {
      return "Mozgásban vagy!";
    } else if (_languageProvider.isGerman) {
      return "Du bist in Bewegung!";
    } else {
      return "You are moving!";
    }
  }

  // No GPS Warning Message
  static String get noGpsWarningMessage {
    if (_languageProvider.isHungarian) {
      return "Nincs GPS jel!";
    } else if (_languageProvider.isGerman) {
      return "Kein GPS-Signal!";
    } else {
      return "No GPS signal!";
    }
  }

  // Choose Measurement Title
  static String get chooseMeasurementTitle {
    if (_languageProvider.isHungarian) {
      return "Válassz mérést";
    } else if (_languageProvider.isGerman) {
      return "Messung auswählen";
    } else {
      return "Choose measurement";
    }
  }

  // Zero To Hundred Label
  static String get zeroToHundredLabel {
    return "0-100";
  }

  // Hundred To Two Hundred Label
  static String get hundredToTwoHundredLabel {
    return "100-200";
  }

  // Settings
  static String get settings {
    if (_languageProvider.isHungarian) {
      return "Beállítások";
    } else if (_languageProvider.isGerman) {
      return "Einstellungen";
    } else {
      return "Settings";
    }
  }

  // Speed Unit
  static String get speedUnit {
    if (_languageProvider.isHungarian) {
      return "Sebességegység";
    } else if (_languageProvider.isGerman) {
      return "Geschwindigkeitseinheit";
    } else {
      return "Speed Unit";
    }
  }

  // Language
  static String get language {
    if (_languageProvider.isHungarian) {
      return "Nyelv";
    } else if (_languageProvider.isGerman) {
      return "Sprache";
    } else {
      return "Language";
    }
  }

  // Hungarian
  static String get hungarian {
    if (_languageProvider.isHungarian) {
      return "Magyar";
    } else if (_languageProvider.isGerman) {
      return "Ungarisch";
    } else {
      return "Hungarian";
    }
  }

  // English
  static String get english {
    if (_languageProvider.isHungarian) {
      return "Angol";
    } else if (_languageProvider.isGerman) {
      return "Englisch";
    } else {
      return "English";
    }
  }

  // German
  static String get german {
    if (_languageProvider.isHungarian) {
      return "Német";
    } else if (_languageProvider.isGerman) {
      return "Deutsch";
    } else {
      return "German";
    }
  }

  // Information
  static String get information {
    if (_languageProvider.isHungarian) {
      return "Információ";
    } else if (_languageProvider.isGerman) {
      return "Information";
    } else {
      return "Information";
    }
  }

  // Profile
  static String get profile {
    if (_languageProvider.isHungarian) {
      return "Profil";
    } else if (_languageProvider.isGerman) {
      return "Profil";
    } else {
      return "Profile";
    }
  }

  // Help Dialog Title
  static String get appInstructions {
    if (_languageProvider.isHungarian) {
      return "Alkalmazás használati útmutató";
    } else if (_languageProvider.isGerman) {
      return "App-Bedienungsanleitung";
    } else {
      return "App Instructions";
    }
  }

  // Help Dialog Content
  static String get appInstructionsContent {
    if (_languageProvider.isHungarian) {
      return """
        Üdvözölünk a DynoMobile alkalmazásban! Az alábbiakban megtalálod az elérhető funkciók áttekintését:
        
        0-100 Mérés: Ez a funkció kiszámítja, mennyi idő alatt gyorsul a járműved 0-ról 100 km/órára. Az időzítő akkor indul, amikor a sebességed meghaladja a 3 km/órát.
        
        100-200 Mérés: Ez a funkció rögzíti a 100-ról 200 km/órára gyorsulás idejét. Az időzítő akkor indul, amikor a sebességed meghaladja a 103 km/órát.
        
        Teljesítménymérés: Ez a funkció kiszámítja járműved teljesítményét lóerőben.
        
        Köridőmérő: A köridőmérő akkor indul, amikor elhagyod a kezdőpozíciót, és akkor áll le, amikor visszatérsz ugyanoda, rögzítve a teljes időtartamot.
        
        Kérjük, vedd figyelembe, hogy a sebességmérő és minden mérés pontatlanságoknak van kitéve. Ez az alkalmazás kizárólag szórakoztatási célokra készült, és nem támaszkodhat pontos teljesítményadatokra.
        
        Vezess biztonságosan és élvezd az alkalmazás használatát!
        """;
    } else if (_languageProvider.isGerman) {
      return """
        Willkommen bei der DynoMobile App! Im Folgenden finden Sie einen Überblick über die verfügbaren Funktionen:
        
        0-100 Messung: Diese Funktion berechnet die Zeit, die Ihr Fahrzeug benötigt, um von 0 auf 100 km/h zu beschleunigen. Der Timer startet, wenn Ihre Geschwindigkeit 3 km/h überschreitet.
        
        100-200 Messung: Diese Funktion erfasst die Zeit für die Beschleunigung von 100 auf 200 km/h. Der Timer startet, wenn Ihre Geschwindigkeit 103 km/h überschreitet.
        
        Leistungsmessung: Diese Funktion berechnet die Leistung Ihres Fahrzeugs in Pferdestärken.
        
        Rundenzeitmesser: Der Rundenzeitmesser startet, wenn Sie Ihre Ausgangsposition verlassen, und stoppt, wenn Sie an denselben Ort zurückkehren, wobei die Gesamtzeit aufgezeichnet wird.
        
        Bitte beachten Sie, dass der Tachometer und alle Messungen Ungenauigkeiten unterliegen. Diese Anwendung ist ausschließlich für Unterhaltungszwecke konzipiert und sollte nicht für präzise Leistungsdaten herangezogen werden.
        
        Fahren Sie sicher und genießen Sie die Nutzung der App!
        """;
    } else {
      return """
        Welcome to the DynoMobile app! Below you will find an overview of the available features:
        
        0-100 Measurement: This function calculates the time it takes for your vehicle to accelerate from 0 to 100 km/h. The timer starts when your speed exceeds 3 km/h.
        
        100-200 Measurement: This function records the time it takes to accelerate from 100 to 200 km/h. The timer starts when your speed surpasses 103 km/h.
        
        Performance Measurement: This feature calculates your vehicle's power output in horsepower.
        
        Lap Timer: The lap timer starts when you leave your initial position and stops when you return to the same location, recording the total time taken.
        
        Please note that the speedometer and all measurements are subject to inaccuracies. This application is designed purely for entertainment purposes and should not be relied upon for precise performance data.
        
        Drive safely and enjoy using the app!        """;
    }
  }

  // OK Button
  static String get ok {
    return "OK"; // This is the same in all languages
  }

  // Competition page strings
  // Daily top button
  static String get dailyTop {
    if (_languageProvider.isHungarian) {
      return "Napi legjobb";
    } else if (_languageProvider.isGerman) {
      return "Tagesbeste";
    } else {
      return "Daily Top";
    }
  }

  // Personal results button
  static String get personalResults {
    if (_languageProvider.isHungarian) {
      return "Saját eredmények";
    } else if (_languageProvider.isGerman) {
      return "Persönliche Ergebnisse";
    } else {
      return "Personal Results";
    }
  }

  // Login required title
  static String get loginRequiredTitle {
    if (_languageProvider.isHungarian) {
      return "Jelentkezz be a versenytáblák megtekintéséhez";
    } else if (_languageProvider.isGerman) {
      return "Melden Sie sich an, um die Wettbewerbstabellen anzuzeigen";
    } else {
      return "Sign in to view competition tables";
    }
  }

  // Login required description
  static String get loginRequiredDescription {
    if (_languageProvider.isHungarian) {
      return "A versenytáblák csak bejelentkezett felhasználók számára érhetők el";
    } else if (_languageProvider.isGerman) {
      return "Wettbewerbstabellen sind nur für angemeldete Benutzer verfügbar";
    } else {
      return "Competition tables are only available to logged-in users";
    }
  }

  // Login button
  static String get login {
    if (_languageProvider.isHungarian) {
      return "Bejelentkezés";
    } else if (_languageProvider.isGerman) {
      return "Anmelden";
    } else {
      return "Login";
    }
  }

  // No personal results
  static String get noPersonalResults {
    if (_languageProvider.isHungarian) {
      return "Még nincsenek mérési eredményeid";
    } else if (_languageProvider.isGerman) {
      return "Sie haben noch keine Messergebnisse";
    } else {
      return "You don't have any measurement results yet";
    }
  }

  // No daily results
  static String get noDailyResults {
    if (_languageProvider.isHungarian) {
      return "Ma még nem születtek eredmények ebben a kategóriában";
    } else if (_languageProvider.isGerman) {
      return "Heute wurden in dieser Kategorie noch keine Ergebnisse erzielt";
    } else {
      return "No results have been recorded in this category today";
    }
  }

  // Cancel button
  static String get cancel {
    if (_languageProvider.isHungarian) {
      return "Mégse";
    } else if (_languageProvider.isGerman) {
      return "Abbrechen";
    } else {
      return "Cancel";
    }
  }

  // Test speed increase
  static String get testSpeedIncrease {
    if (_languageProvider.isHungarian) {
      return "Teszt Sebesség Növelés";
    } else if (_languageProvider.isGerman) {
      return "Test Geschwindigkeitssteigerung";
    } else {
      return "Test Speed Increase";
    }
  }

  // Measurement started
  static String get measurementStarted {
    if (_languageProvider.isHungarian) {
      return "A mérés elkezdődött!";
    } else if (_languageProvider.isGerman) {
      return "Die Messung hat begonnen!";
    } else {
      return "Measurement started!";
    }
  }

  // Vehicle is moving
  static String get vehicleIsMoving {
    if (_languageProvider.isHungarian) {
      return "A jármű mozgásban van!";
    } else if (_languageProvider.isGerman) {
      return "Das Fahrzeug ist in Bewegung!";
    } else {
      return "The vehicle is moving!";
    }
  }

  // Second unit
  static String get second {
    if (_languageProvider.isHungarian) {
      return "mp";
    } else if (_languageProvider.isGerman) {
      return "Sek";
    } else {
      return "sec";
    }
  }

  // === Login Page Strings ===
  // Login title
  static String get loginTitle {
    if (_languageProvider.isHungarian) {
      return "Bejelentkezés";
    } else if (_languageProvider.isGerman) {
      return "Anmelden";
    } else {
      return "Log in";
    }
  }

  // Email Address
  static String get emailAddress {
    if (_languageProvider.isHungarian) {
      return "Email cím";
    } else if (_languageProvider.isGerman) {
      return "E-Mail-Adresse";
    } else {
      return "Email Address";
    }
  }

  // Enter your email hint
  static String get enterYourEmail {
    if (_languageProvider.isHungarian) {
      return "Add meg az email címed";
    } else if (_languageProvider.isGerman) {
      return "Geben Sie Ihre E-Mail ein";
    } else {
      return "Enter your email";
    }
  }

  // Password
  static String get password {
    if (_languageProvider.isHungarian) {
      return "Jelszó";
    } else if (_languageProvider.isGerman) {
      return "Passwort";
    } else {
      return "Password";
    }
  }

  // Enter your password hint
  static String get enterYourPassword {
    if (_languageProvider.isHungarian) {
      return "Add meg a jelszavad";
    } else if (_languageProvider.isGerman) {
      return "Geben Sie Ihr Passwort ein";
    } else {
      return "Enter your password";
    }
  }

  // Enter email and password
  static String get enterEmailAndPassword {
    if (_languageProvider.isHungarian) {
      return "Add meg az email címed és jelszavad!";
    } else if (_languageProvider.isGerman) {
      return "Bitte geben Sie Ihre E-Mail und Ihr Passwort ein!";
    } else {
      return "Please enter your email and password!";
    }
  }

  // Reset Password
  static String get resetPassword {
    if (_languageProvider.isHungarian) {
      return "Jelszó visszaállítása";
    } else if (_languageProvider.isGerman) {
      return "Passwort zurücksetzen";
    } else {
      return "Reset Password";
    }
  }

  // Reset button text
  static String get reset {
    if (_languageProvider.isHungarian) {
      return "Visszaállítás";
    } else if (_languageProvider.isGerman) {
      return "Zurücksetzen";
    } else {
      return "Reset";
    }
  }

  // Enter email to reset password
  static String get enterEmailToResetPassword {
    if (_languageProvider.isHungarian) {
      return "Add meg az email címed a jelszó visszaállításához";
    } else if (_languageProvider.isGerman) {
      return "Geben Sie Ihre E-Mail-Adresse ein, um Ihr Passwort zurückzusetzen";
    } else {
      return "Enter your email address to reset your password";
    }
  }

  // Forgot Password
  static String get forgotPassword {
    if (_languageProvider.isHungarian) {
      return "Elfelejtett jelszó?";
    } else if (_languageProvider.isGerman) {
      return "Passwort vergessen?";
    } else {
      return "Forgot Password?";
    }
  }

  // Bottom navigation bar items
  static String get measure {
    if (_languageProvider.isHungarian) {
      return "Mérés";
    } else if (_languageProvider.isGerman) {
      return "Messen";
    } else {
      return "Measure";
    }
  }

  static String get home {
    if (_languageProvider.isHungarian) {
      return "Kezdőlap";
    } else if (_languageProvider.isGerman) {
      return "Startseite";
    } else {
      return "Home";
    }
  }

  static String get dyno {
    if (_languageProvider.isHungarian) {
      return "Dyno";
    } else if (_languageProvider.isGerman) {
      return "Dyno";
    } else {
      return "Dyno";
    }
  }

  static String get laptime {
    if (_languageProvider.isHungarian) {
      return "Köridő";
    } else if (_languageProvider.isGerman) {
      return "Rundenzeit";
    } else {
      return "Laptime";
    }
  }

  // Competition label for navigation
  static String get competition {
    if (_languageProvider.isHungarian) {
      return "Verseny";
    } else if (_languageProvider.isGerman) {
      return "Wettbewerb";
    } else {
      return "Competition";
    }
  }

  // Password requirements messages
  static String get atLeast8Chars {
    if (_languageProvider.isHungarian) {
      return "Legalább 8 karakter";
    } else if (_languageProvider.isGerman) {
      return "Mindestens 8 Zeichen";
    } else {
      return "At least 8 characters";
    }
  }

  static String get atLeastOneUppercase {
    if (_languageProvider.isHungarian) {
      return "Legalább egy nagybetű";
    } else if (_languageProvider.isGerman) {
      return "Mindestens ein Großbuchstabe";
    } else {
      return "At least one uppercase letter";
    }
  }

  static String get atLeastOneNumber {
    if (_languageProvider.isHungarian) {
      return "Legalább egy szám";
    } else if (_languageProvider.isGerman) {
      return "Mindestens eine Zahl";
    } else {
      return "At least one number";
    }
  }

  // Password validation warnings
  static String get meetPasswordRequirements {
    if (_languageProvider.isHungarian) {
      return "Kérlek teljesítsd a jelszó követelményeket";
    } else if (_languageProvider.isGerman) {
      return "Bitte erfüllen Sie die Passwortanforderungen";
    } else {
      return "Please meet all password requirements";
    }
  }

  static String get passwordsDontMatch {
    if (_languageProvider.isHungarian) {
      return "A jelszavak nem egyeznek!";
    } else if (_languageProvider.isGerman) {
      return "Passwörter stimmen nicht überein!";
    } else {
      return "Passwords do not match!";
    }
  }

  static String get enterValidEmail {
    if (_languageProvider.isHungarian) {
      return "Kérlek adj meg érvényes e-mail címet!";
    } else if (_languageProvider.isGerman) {
      return "Bitte gib eine gültige E-Mail-Adresse ein!";
    } else {
      return "Please enter a valid email address!";
    }
  }

  // Confirm password
  static String get confirmPassword {
    if (_languageProvider.isHungarian) {
      return "Jelszó megerősítése";
    } else if (_languageProvider.isGerman) {
      return "Passwort bestätigen";
    } else {
      return "Confirm Password";
    }
  }

  static String get confirmYourPassword {
    if (_languageProvider.isHungarian) {
      return "Erősítsd meg a jelszavad";
    } else if (_languageProvider.isGerman) {
      return "Bestätigen Sie Ihr Passwort";
    } else {
      return "Confirm your password";
    }
  }

  // Sign Up button
  static String get signUp {
    if (_languageProvider.isHungarian) {
      return "Regisztráció";
    } else if (_languageProvider.isGerman) {
      return "Anmelden";
    } else {
      return "Sign Up";
    }
  }

  // Back button
  static String get back {
    if (_languageProvider.isHungarian) {
      return "Vissza";
    } else if (_languageProvider.isGerman) {
      return "Zurück";
    } else {
      return "Back";
    }
  }

  // Already have account
  static String get alreadyHaveAccount {
    if (_languageProvider.isHungarian) {
      return "Már van fiókod? ";
    } else if (_languageProvider.isGerman) {
      return "Haben Sie bereits ein Konto? ";
    } else {
      return "Already Have Account? ";
    }
  }

  // Create Account text for signup link
  static String get createAccount {
    if (_languageProvider.isHungarian) {
      return "Fiók létrehozása";
    } else if (_languageProvider.isGerman) {
      return "Konto erstellen";
    } else {
      return "Create Account";
    }
  }

  // Log in button text
  static String get logIn {
    if (_languageProvider.isHungarian) {
      return "Bejelentkezés";
    } else if (_languageProvider.isGerman) {
      return "Anmelden";
    } else {
      return "Log In";
    }
  }

  // Location Services Disabled
  static String get locationServicesDisabled {
    if (_languageProvider.isHungarian) {
      return "Helymeghatározási szolgáltatások kikapcsolva";
    } else if (_languageProvider.isGerman) {
      return "Standortdienste deaktiviert";
    } else {
      return "Location Services Disabled";
    }
  }

  // Location permission denied
  static String get locationPermissionDenied {
    if (_languageProvider.isHungarian) {
      return "Helymeghatározási engedély megtagadva";
    } else if (_languageProvider.isGerman) {
      return "Standortberechtigung verweigert";
    } else {
      return "Location Permission Denied";
    }
  }

  // Enable location services message
  static String get enableLocationServices {
    if (_languageProvider.isHungarian) {
      return "Kérjük, kapcsolja be a helymeghatározási szolgáltatásokat a beállításokban az alkalmazás használatához.";
    } else if (_languageProvider.isGerman) {
      return "Bitte aktivieren Sie die Standortdienste in den Einstellungen, um diese Anwendung zu nutzen.";
    } else {
      return "Please enable location services in settings to use this application.";
    }
  }

  // Allow location access message
  static String get allowLocationAccess {
    if (_languageProvider.isHungarian) {
      return "Az alkalmazás használatához engedélyeznie kell a helymeghatározást az alkalmazás beállításaiban.";
    } else if (_languageProvider.isGerman) {
      return "Sie müssen den Standortzugriff in den App-Einstellungen erlauben, um diese Anwendung zu nutzen.";
    } else {
      return "You need to allow location access in app settings to use this application.";
    }
  }

  // Open settings button
  static String get openSettings {
    if (_languageProvider.isHungarian) {
      return "Beállítások megnyitása";
    } else if (_languageProvider.isGerman) {
      return "Einstellungen öffnen";
    } else {
      return "Open Settings";
    }
  }

  // Allow access button
  static String get allowAccess {
    if (_languageProvider.isHungarian) {
      return "Hozzáférés engedélyezése";
    } else if (_languageProvider.isGerman) {
      return "Zugriff erlauben";
    } else {
      return "Allow Access";
    }
  }

  // Settings button
  static String get settingsButton {
    if (_languageProvider.isHungarian) {
      return "Beállítások";
    } else if (_languageProvider.isGerman) {
      return "Einstellungen";
    } else {
      return "Settings";
    }
  }

  // Sign In button text
  static String get signIn {
    if (_languageProvider.isHungarian) {
      return "Belépés";
    } else if (_languageProvider.isGerman) {
      return "Anmelden";
    } else {
      return "Sign In";
    }
  }

  // Guest button text
  static String get guest {
    if (_languageProvider.isHungarian) {
      return "Vendég";
    } else if (_languageProvider.isGerman) {
      return "Gast";
    } else {
      return "Guest";
    }
  }

  // New User text
  static String get newUser {
    if (_languageProvider.isHungarian) {
      return "Új felhasználó? ";
    } else if (_languageProvider.isGerman) {
      return "Neuer Benutzer? ";
    } else {
      return "New User? ";
    }
  }

  // Register Account title
  static String get registerAccount {
    if (_languageProvider.isHungarian) {
      return "Fiók regisztrálása";
    } else if (_languageProvider.isGerman) {
      return "Konto registrieren";
    } else {
      return "Register Account";
    }
  }
}
