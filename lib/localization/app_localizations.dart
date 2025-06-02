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

  // Profile page section headers
  static String get accountInformation {
    if (_languageProvider.isHungarian) {
      return "Felhasználói adatok";
    } else if (_languageProvider.isGerman) {
      return "Kontoinformationen";
    } else {
      return "Account Information";
    }
  }

  static String get accountSettings {
    if (_languageProvider.isHungarian) {
      return "Fiók beállítások";
    } else if (_languageProvider.isGerman) {
      return "Kontoeinstellungen";
    } else {
      return "Account Settings";
    }
  }

  // Profile page info rows
  static String get car {
    if (_languageProvider.isHungarian) {
      return "Autó";
    } else if (_languageProvider.isGerman) {
      return "Auto";
    } else {
      return "Car";
    }
  }

  static String get noCarSelected {
    if (_languageProvider.isHungarian) {
      return "Nincs autó kiválasztva";
    } else if (_languageProvider.isGerman) {
      return "Kein Auto ausgewählt";
    } else {
      return "No car selected";
    }
  }

  static String get instagram {
    if (_languageProvider.isHungarian) {
      return "Instagram";
    } else if (_languageProvider.isGerman) {
      return "Instagram";
    } else {
      return "Instagram";
    }
  }

  static String get noInstagramUsername {
    if (_languageProvider.isHungarian) {
      return "Nincs Instagram felhasználónév";
    } else if (_languageProvider.isGerman) {
      return "Kein Instagram-Benutzername";
    } else {
      return "No Instagram username";
    }
  }

  // Profile page action rows
  static String get changePassword {
    if (_languageProvider.isHungarian) {
      return "Jelszó módosítása";
    } else if (_languageProvider.isGerman) {
      return "Passwort ändern";
    } else {
      return "Change Password";
    }
  }

  static String get logOut {
    if (_languageProvider.isHungarian) {
      return "Kijelentkezés";
    } else if (_languageProvider.isGerman) {
      return "Abmelden";
    } else {
      return "Log Out";
    }
  }

  static String get deleteAccount {
    if (_languageProvider.isHungarian) {
      return "Fiók törlése";
    } else if (_languageProvider.isGerman) {
      return "Konto löschen";
    } else {
      return "Delete Account";
    }
  }

  // Car dialog
  static String get selectCar {
    if (_languageProvider.isHungarian) {
      return "Autó kiválasztása";
    } else if (_languageProvider.isGerman) {
      return "Auto auswählen";
    } else {
      return "Select Car";
    }
  }

  static String get enterCarModel {
    if (_languageProvider.isHungarian) {
      return "Add meg az autó típusát";
    } else if (_languageProvider.isGerman) {
      return "Automodell eingeben";
    } else {
      return "Enter car model";
    }
  }

  static String get carExamples {
    if (_languageProvider.isHungarian) {
      return "Például: BMW M3, Audi RS6, Tesla Model 3";
    } else if (_languageProvider.isGerman) {
      return "Beispiel: BMW M3, Audi RS6, Tesla Model 3";
    } else {
      return "Example: BMW M3, Audi RS6, Tesla Model 3";
    }
  }

  // Instagram dialog
  static String get instagramUsername {
    if (_languageProvider.isHungarian) {
      return "Instagram felhasználónév";
    } else if (_languageProvider.isGerman) {
      return "Instagram-Benutzername";
    } else {
      return "Instagram Username";
    }
  }

  static String get enterInstagramUsername {
    if (_languageProvider.isHungarian) {
      return "Add meg az Instagram felhasználónevedet";
    } else if (_languageProvider.isGerman) {
      return "Geben Sie Ihren Instagram-Benutzernamen ein";
    } else {
      return "Enter your Instagram username";
    }
  }

  static String get instagramUsernameInfo {
    if (_languageProvider.isHungarian) {
      return "Add meg az Instagram felhasználónevedet @ jel nélkül";
    } else if (_languageProvider.isGerman) {
      return "Geben Sie Ihren Instagram-Benutzernamen ohne das @-Symbol ein";
    } else {
      return "Enter your Instagram username without the @ symbol";
    }
  }

  // Common dialog buttons
  static String get save {
    if (_languageProvider.isHungarian) {
      return "Mentés";
    } else if (_languageProvider.isGerman) {
      return "Speichern";
    } else {
      return "Save";
    }
  }

  static String get cancel {
    if (_languageProvider.isHungarian) {
      return "Mégse";
    } else if (_languageProvider.isGerman) {
      return "Abbrechen";
    } else {
      return "Cancel";
    }
  }

  // Edit nickname
  static String get editNickname {
    if (_languageProvider.isHungarian) {
      return "Becenév szerkesztése";
    } else if (_languageProvider.isGerman) {
      return "Spitznamen bearbeiten";
    } else {
      return "Edit Nickname";
    }
  }

  static String get enterNickname {
    if (_languageProvider.isHungarian) {
      return "Add meg a becenevedet (max. 10 karakter)";
    } else if (_languageProvider.isGerman) {
      return "Geben Sie Ihren Spitznamen ein (max. 10 Zeichen)";
    } else {
      return "Enter nickname (max 10 chars)";
    }
  }

  // Validation errors
  static String get usernameNoSpaces {
    if (_languageProvider.isHungarian) {
      return "A felhasználónév nem tartalmazhat szóközt";
    } else if (_languageProvider.isGerman) {
      return "Benutzername darf keine Leerzeichen enthalten";
    } else {
      return "Spaces are not allowed in Instagram usernames";
    }
  }

  static String get usernameInvalidChars {
    if (_languageProvider.isHungarian) {
      return "Csak betűk, számok, aláhúzás és pont engedélyezett";
    } else if (_languageProvider.isGerman) {
      return "Nur Buchstaben, Zahlen, Unterstriche und Punkte sind erlaubt";
    } else {
      return "Only letters, numbers, underscore and periods allowed";
    }
  }

  static String get usernameMaxLength {
    if (_languageProvider.isHungarian) {
      return "A felhasználónév nem lehet hosszabb 30 karakternél";
    } else if (_languageProvider.isGerman) {
      return "Benutzername darf 30 Zeichen nicht überschreiten";
    } else {
      return "Username cannot exceed 30 characters";
    }
  }

  static String get carModelEmpty {
    if (_languageProvider.isHungarian) {
      return "Az autó típusa nem lehet üres";
    } else if (_languageProvider.isGerman) {
      return "Automodell darf nicht leer sein";
    } else {
      return "Car model cannot be empty";
    }
  }

  static String get carModelTooShort {
    if (_languageProvider.isHungarian) {
      return "Az autó típusa túl rövid";
    } else if (_languageProvider.isGerman) {
      return "Automodell ist zu kurz";
    } else {
      return "Car model is too short";
    }
  }

  static String get carModelTooLong {
    if (_languageProvider.isHungarian) {
      return "Az autó típusa nem lehet hosszabb 25 karakternél";
    } else if (_languageProvider.isGerman) {
      return "Automodell darf 25 Zeichen nicht überschreiten";
    } else {
      return "Car model cannot exceed 25 characters";
    }
  }

  // Password change dialog
  static String get currentPassword {
    if (_languageProvider.isHungarian) {
      return "Jelenlegi jelszó";
    } else if (_languageProvider.isGerman) {
      return "Aktuelles Passwort";
    } else {
      return "Current password";
    }
  }

  static String get newPassword {
    if (_languageProvider.isHungarian) {
      return "Új jelszó";
    } else if (_languageProvider.isGerman) {
      return "Neues Passwort";
    } else {
      return "New password";
    }
  }

  static String get confirmNewPassword {
    if (_languageProvider.isHungarian) {
      return "Új jelszó megerősítése";
    } else if (_languageProvider.isGerman) {
      return "Neues Passwort bestätigen";
    } else {
      return "Confirm new password";
    }
  }

  static String get allFieldsRequired {
    if (_languageProvider.isHungarian) {
      return "Minden mező kitöltése kötelező!";
    } else if (_languageProvider.isGerman) {
      return "Alle Felder sind erforderlich!";
    } else {
      return "All fields are required!";
    }
  }

  static String get passwordsDoNotMatch {
    if (_languageProvider.isHungarian) {
      return "Az új jelszavak nem egyeznek!";
    } else if (_languageProvider.isGerman) {
      return "Die neuen Passwörter stimmen nicht überein!";
    } else {
      return "The new passwords don't match!";
    }
  }

  static String get passwordCannotBeSame {
    if (_languageProvider.isHungarian) {
      return "Az új jelszó nem lehet ugyanaz, mint a jelenlegi!";
    } else if (_languageProvider.isGerman) {
      return "Das neue Passwort darf nicht mit dem aktuellen identisch sein!";
    } else {
      return "The new password cannot be the same as the current one!";
    }
  }

  static String get currentPasswordIncorrect {
    if (_languageProvider.isHungarian) {
      return "A jelenlegi jelszó helytelen!";
    } else if (_languageProvider.isGerman) {
      return "Das aktuelle Passwort ist falsch!";
    } else {
      return "Current password is incorrect!";
    }
  }

  static String get passwordChangedSuccessfully {
    if (_languageProvider.isHungarian) {
      return "Jelszó sikeresen módosítva!";
    } else if (_languageProvider.isGerman) {
      return "Passwort erfolgreich geändert!";
    } else {
      return "Password changed successfully!";
    }
  }

  // Logout dialog
  static String get logoutConfirmation {
    if (_languageProvider.isHungarian) {
      return "Biztosan ki szeretnél jelentkezni?";
    } else if (_languageProvider.isGerman) {
      return "Möchten Sie sich wirklich abmelden?";
    } else {
      return "Are you sure you want to log out?";
    }
  }

  // Delete account dialog
  static String get deleteAccountConfirmation {
    if (_languageProvider.isHungarian) {
      return "Biztosan törölni szeretnéd a fiókodat?\nEz a művelet nem visszavonható!";
    } else if (_languageProvider.isGerman) {
      return "Sind Sie sicher, dass Sie Ihr Konto löschen möchten?\nDiese Aktion kann nicht rückgängig gemacht werden!";
    } else {
      return "Are you sure you want to delete your account?\nThis action cannot be undone!";
    }
  }

  // Success messages
  static String get nicknameUpdated {
    if (_languageProvider.isHungarian) {
      return "Becenév sikeresen módosítva!";
    } else if (_languageProvider.isGerman) {
      return "Spitzname erfolgreich aktualisiert!";
    } else {
      return "Nickname successfully updated!";
    }
  }

  static String get profilePictureUpdated {
    if (_languageProvider.isHungarian) {
      return "Profilkép sikeresen módosítva!";
    } else if (_languageProvider.isGerman) {
      return "Profilbild erfolgreich aktualisiert!";
    } else {
      return "Profile picture successfully updated!";
    }
  }

  static String get carUpdated {
    if (_languageProvider.isHungarian) {
      return "Autó sikeresen módosítva!";
    } else if (_languageProvider.isGerman) {
      return "Auto erfolgreich aktualisiert!";
    } else {
      return "Car successfully updated!";
    }
  }

  static String get instagramUpdated {
    if (_languageProvider.isHungarian) {
      return "Instagram felhasználónév sikeresen módosítva!";
    } else if (_languageProvider.isGerman) {
      return "Instagram-Benutzername erfolgreich aktualisiert!";
    } else {
      return "Instagram username successfully updated!";
    }
  }

  // Error messages
  static String get emptyNickname {
    if (_languageProvider.isHungarian) {
      return "A becenév nem lehet üres!";
    } else if (_languageProvider.isGerman) {
      return "Der Spitzname darf nicht leer sein!";
    } else {
      return "Nickname cannot be empty!";
    }
  }

  static String get nicknameTooLong {
    if (_languageProvider.isHungarian) {
      return "A becenév maximum 10 karakter lehet!";
    } else if (_languageProvider.isGerman) {
      return "Der Spitzname darf maximal 10 Zeichen lang sein!";
    } else {
      return "Nickname cannot exceed 10 characters!";
    }
  }

  // Google bejelentkezés gombhoz
  static String get signInWithGoogle {
    if (_languageProvider.isHungarian) {
      return "Google bejelentkezés";
    } else if (_languageProvider.isGerman) {
      return "Mit Google anmelden";
    } else {
      return "Sign in with Google";
    }
  }

  // "vagy" szöveghez
  static String get or {
    if (_languageProvider.isHungarian) {
      return "vagy";
    } else if (_languageProvider.isGerman) {
      return "oder";
    } else {
      return "or";
    }
  }

  // Google bejelentkezési hiba üzenethez
  static String get googleSignInError {
    if (_languageProvider.isHungarian) {
      return "Google bejelentkezési hiba";
    } else if (_languageProvider.isGerman) {
      return "Google-Anmeldungsfehler";
    } else {
      return "Google sign-in error";
    }
  }

  // Google bejelentkezés megszakítva üzenethez
  static String get googleSignInCanceled {
    if (_languageProvider.isHungarian) {
      return "Google bejelentkezés megszakítva";
    } else if (_languageProvider.isGerman) {
      return "Google-Anmeldung abgebrochen";
    } else {
      return "Google sign-in canceled";
    }
  }

  // Művelet időtúllépés üzenethez
  static String get operationTimedOut {
    if (_languageProvider.isHungarian) {
      return "A művelet túl sok időt vett igénybe";
    } else if (_languageProvider.isGerman) {
      return "Der Vorgang hat zu viel Zeit in Anspruch genommen";
    } else {
      return "The operation timed out";
    }
  }

  // Regisztráció sikertelen üzenethez
  static String get registrationFailed {
    if (_languageProvider.isHungarian) {
      return "Regisztráció sikertelen";
    } else if (_languageProvider.isGerman) {
      return "Registrierung fehlgeschlagen";
    } else {
      return "Registration failed";
    }
  }

  static String get error {
    if (_languageProvider.isHungarian) {
      return "Hiba";
    } else if (_languageProvider.isGerman) {
      return "Fehler";
    } else {
      return "Error";
    }
  }

  // A közvetlen "No results" segítő szövegek
  static String get createMeasurementsMessage {
    if (_languageProvider.isHungarian) {
      return "Készíts méréseket, hogy eredményeid legyenek!";
    } else if (_languageProvider.isGerman) {
      return "Führe Messungen durch, um Ergebnisse zu erhalten!";
    } else {
      return "Create measurements to see your results here!";
    }
  }

  static String get noResultsYetMessage {
    if (_languageProvider.isHungarian) {
      return "Ma még nem született eredmény. Légy te az első!";
    } else if (_languageProvider.isGerman) {
      return "Heute wurden noch keine Ergebnisse erzielt. Sei der Erste!";
    } else {
      return "No results recorded today. Be the first one!";
    }
  }

  static String get startMeasuring {
    if (_languageProvider.isHungarian) {
      return "Mérés indítása";
    } else if (_languageProvider.isGerman) {
      return "Messung starten";
    } else {
      return "Start measuring";
    }
  }

  // Result dialog másodperc formátum
  static String formatElapsedTimeMillis(Duration elapsedTime) {
    if (_languageProvider.isHungarian) {
      return "${elapsedTime.inSeconds}.${elapsedTime.inMilliseconds % 1000} másodperc";
    } else if (_languageProvider.isGerman) {
      return "${elapsedTime.inSeconds}.${elapsedTime.inMilliseconds % 1000} Sekunden";
    } else {
      return "${elapsedTime.inSeconds}.${elapsedTime.inMilliseconds % 1000} seconds";
    }
  }

  // User label a competition oldalon
  static String get user {
    if (_languageProvider.isHungarian) {
      return "Felhasználó";
    } else if (_languageProvider.isGerman) {
      return "Benutzer";
    } else {
      return "User";
    }
  }

  // Error prefix
  static String errorWithMessage(String message) {
    if (_languageProvider.isHungarian) {
      return "Hiba: $message";
    } else if (_languageProvider.isGerman) {
      return "Fehler: $message";
    } else {
      return "Error: $message";
    }
  }

  // Competitions táblázat fejléc: Eredmény
  static String get result {
    if (_languageProvider.isHungarian) {
      return "Eredmény";
    } else if (_languageProvider.isGerman) {
      return "Ergebnis";
    } else {
      return "Result";
    }
  }

  // ¼ Mile felirat szövege
  static String get quarterMile {
    if (_languageProvider.isHungarian) {
      return "¼ Mérföld";
    } else if (_languageProvider.isGerman) {
      return "¼ Meile";
    } else {
      return "¼ Mile";
    }
  }

  // ¼ Mile Time eredmény szöveg
  static String get quarterMileTime {
    if (_languageProvider.isHungarian) {
      return "¼ Mérföld Idő";
    } else if (_languageProvider.isGerman) {
      return "¼ Meile Zeit";
    } else {
      return "¼ Mile Time";
    }
  }

  // Megerősítés leírása változásokhoz (pl. törlés esetén)
  static String get confirmAction {
    if (_languageProvider.isHungarian) {
      return "MÉGSE";
    } else if (_languageProvider.isGerman) {
      return "ABBRECHEN";
    } else {
      return "CANCEL";
    }
  }

  static String get confirmActionYes {
    if (_languageProvider.isHungarian) {
      return "IGEN";
    } else if (_languageProvider.isGerman) {
      return "JA";
    } else {
      return "YES";
    }
  }

  // Add this new getter near other password-related strings (around line 1040-1080)

  static String get changePasswordDescription {
    if (_languageProvider.isHungarian) {
      return "A jelszó módosításához add meg jelenlegi jelszavad, majd az új jelszót kétszer.";
    } else if (_languageProvider.isGerman) {
      return "Geben Sie Ihr aktuelles Passwort und dann zweimal Ihr neues Passwort ein, um es zu ändern.";
    } else {
      return "To change your password, enter your current password, then enter your new password twice.";
    }
  }

  static String get carAlreadySelected {
    if (_languageProvider.isHungarian) {
      return "Ez az autó már ki van választva!";
    } else if (_languageProvider.isGerman) {
      return "Dieses Auto ist bereits ausgewählt!";
    } else {
      return "This car is already selected!";
    }
  }

  static String get instagramUsernameAlreadySet {
    if (_languageProvider.isHungarian) {
      return "Ez az Instagram felhasználónév már be van állítva!";
    } else if (_languageProvider.isGerman) {
      return "Dieser Instagram-Benutzername ist bereits eingestellt!";
    } else {
      return "This Instagram username is already set!";
    }
  }

  static String get nicknameAlreadySet {
    if (_languageProvider.isHungarian) {
      return "Ez a becenév már be van állítva!";
    } else if (_languageProvider.isGerman) {
      return "Dieser Spitzname ist bereits eingestellt!";
    } else {
      return "This nickname is already set!";
    }
  }

  static String get nicknameInfo {
    if (_languageProvider.isHungarian) {
      return "A beceneved látható lesz más felhasználók számára. Maximum 10 karakter engedélyezett.";
    } else if (_languageProvider.isGerman) {
      return "Dein Spitzname wird für andere Benutzer sichtbar sein. Maximal 10 Zeichen erlaubt.";
    } else {
      return "Your nickname will be visible to other users. Maximum 10 characters allowed.";
    }
  }

  // Auth related messages
  static String get nicknameAlreadyTaken {
    if (_languageProvider.isHungarian) {
      return "Ez a becenév már foglalt!";
    } else if (_languageProvider.isGerman) {
      return "Dieser Spitzname ist bereits vergeben!";
    } else {
      return "This nickname is already taken!";
    }
  }

  static String get registrationSuccessVerifyEmail {
    if (_languageProvider.isHungarian) {
      return "Sikeres regisztráció! Kérjük, erősítsd meg az e-mail címedet 24 órán belül, különben a fiókod törlésre kerül.";
    } else if (_languageProvider.isGerman) {
      return "Registrierung erfolgreich! Bitte bestätigen Sie Ihre E-Mail-Adresse innerhalb von 24 Stunden, sonst wird Ihr Konto gelöscht.";
    } else {
      return "Registration successful! Please verify your email within 24 hours or your account will be deleted.";
    }
  }

  static String get weakPassword {
    if (_languageProvider.isHungarian) {
      return "A megadott jelszó túl gyenge.";
    } else if (_languageProvider.isGerman) {
      return "Das angegebene Passwort ist zu schwach.";
    } else {
      return "The password provided is too weak.";
    }
  }

  static String get emailAlreadyInUse {
    if (_languageProvider.isHungarian) {
      return "Ezzel az e-mail címmel már létezik fiók.";
    } else if (_languageProvider.isGerman) {
      return "Mit dieser E-Mail-Adresse existiert bereits ein Konto.";
    } else {
      return "An account already exists with that email.";
    }
  }

  static String get invalidEmailFormat {
    if (_languageProvider.isHungarian) {
      return "Érvénytelen e-mail formátum.";
    } else if (_languageProvider.isGerman) {
      return "Ungültiges E-Mail-Format.";
    } else {
      return "Invalid email format.";
    }
  }

  static String get emailPasswordRegistrationDisabled {
    if (_languageProvider.isHungarian) {
      return "E-mail/jelszó regisztráció nem engedélyezett.";
    } else if (_languageProvider.isGerman) {
      return "E-Mail/Passwort-Registrierung ist nicht aktiviert.";
    } else {
      return "Email/password registration is not enabled.";
    }
  }

  static String get tooManyRequests {
    if (_languageProvider.isHungarian) {
      return "Túl sok kérés. Próbáld újra később.";
    } else if (_languageProvider.isGerman) {
      return "Zu viele Anfragen. Versuchen Sie es später erneut.";
    } else {
      return "Too many requests. Try again later.";
    }
  }

  static String registrationError(String errorMessage) {
    if (_languageProvider.isHungarian) {
      return "Regisztrációs hiba: $errorMessage";
    } else if (_languageProvider.isGerman) {
      return "Registrierungsfehler: $errorMessage";
    } else {
      return "Registration error: $errorMessage";
    }
  }

  static String get noInternetConnection {
    if (_languageProvider.isHungarian) {
      return "Nincs internet kapcsolat. Ellenőrizd a hálózati beállításaidat.";
    } else if (_languageProvider.isGerman) {
      return "Keine Internetverbindung. Bitte überprüfen Sie Ihre Netzwerkeinstellungen.";
    } else {
      return "No internet connection. Please check your network settings.";
    }
  }

  static String get verificationEmailResent {
    if (_languageProvider.isHungarian) {
      return "Ellenőrző e-mail újraküldve. Kérjük, ellenőrizd a postafiókod.";
    } else if (_languageProvider.isGerman) {
      return "Bestätigungs-E-Mail erneut gesendet. Bitte überprüfen Sie Ihren Posteingang.";
    } else {
      return "Verification email resent. Please check your inbox.";
    }
  }

  static String get verificationEmailSendFailed {
    if (_languageProvider.isHungarian) {
      return "Nem sikerült elküldeni az ellenőrző e-mailt. Kérjük, próbáld újra később.";
    } else if (_languageProvider.isGerman) {
      return "Senden der Bestätigungs-E-Mail fehlgeschlagen. Bitte versuchen Sie es später erneut.";
    } else {
      return "Failed to send verification email. Please try again later.";
    }
  }

  static String get pleaseVerifyEmail {
    if (_languageProvider.isHungarian) {
      return "Kérjük, ellenőrizd az e-mail címed a bejelentkezés előtt. Ellenőrizd a postafiókod.";
    } else if (_languageProvider.isGerman) {
      return "Bitte bestätigen Sie Ihre E-Mail-Adresse vor dem Anmelden. Überprüfen Sie Ihren Posteingang.";
    } else {
      return "Please verify your email before logging in. Check your inbox.";
    }
  }

  static String get emailNotVerified {
    if (_languageProvider.isHungarian) {
      return "E-mail nincs megerősítve";
    } else if (_languageProvider.isGerman) {
      return "E-Mail nicht bestätigt";
    } else {
      return "Email Not Verified";
    }
  }

  static String get resendVerificationEmailQuestion {
    if (_languageProvider.isHungarian) {
      return "Szeretnéd újraküldeni az ellenőrző e-mailt?";
    } else if (_languageProvider.isGerman) {
      return "Möchten Sie die Bestätigungs-E-Mail erneut senden?";
    } else {
      return "Would you like to resend the verification email?";
    }
  }

  static String get resend {
    if (_languageProvider.isHungarian) {
      return "Újraküldés";
    } else if (_languageProvider.isGerman) {
      return "Erneut senden";
    } else {
      return "Resend";
    }
  }

  static String get signInError {
    if (_languageProvider.isHungarian) {
      return "Hiba történt a bejelentkezés során";
    } else if (_languageProvider.isGerman) {
      return "Während der Anmeldung ist ein Fehler aufgetreten";
    } else {
      return "An error occurred during sign in";
    }
  }

  static String get noUserFound {
    if (_languageProvider.isHungarian) {
      return "Nem található felhasználó ezzel az e-mail címmel.";
    } else if (_languageProvider.isGerman) {
      return "Kein Benutzer mit dieser E-Mail-Adresse gefunden.";
    } else {
      return "No user found for that email.";
    }
  }

  static String get wrongPassword {
    if (_languageProvider.isHungarian) {
      return "Hibás jelszó a felhasználóhoz.";
    } else if (_languageProvider.isGerman) {
      return "Falsches Passwort für diesen Benutzer angegeben.";
    } else {
      return "Wrong password provided for that user.";
    }
  }

  static String get passwordResetEmailSent {
    if (_languageProvider.isHungarian) {
      return "Jelszó-visszaállítási e-mail elküldve. Kérjük, ellenőrizd a postafiókod.";
    } else if (_languageProvider.isGerman) {
      return "E-Mail zum Zurücksetzen des Passworts gesendet. Bitte überprüfen Sie Ihren Posteingang.";
    } else {
      return "Password reset email sent. Please check your inbox.";
    }
  }

  static String get errorOccurred {
    if (_languageProvider.isHungarian) {
      return "Hiba történt";
    } else if (_languageProvider.isGerman) {
      return "Ein Fehler ist aufgetreten";
    } else {
      return "An error occurred";
    }
  }

  static String get enterPasswordToConfirm {
    if (_languageProvider.isHungarian) {
      return "Add meg a jelszavad a törlés megerősítéséhez";
    } else if (_languageProvider.isGerman) {
      return "Geben Sie Ihr Passwort ein, um das Löschen zu bestätigen";
    } else {
      return "Enter your password to confirm deletion";
    }
  }

  static String get passwordRequired {
    if (_languageProvider.isHungarian) {
      return "A jelszó megadása kötelező";
    } else if (_languageProvider.isGerman) {
      return "Passwort ist erforderlich";
    } else {
      return "Password is required";
    }
  }

  static String get googleAccountDeleteInfo {
    if (_languageProvider.isHungarian) {
      return "Google fiókkal vagy bejelentkezve. A fiókod törlése után újra regisztrálhatsz, de minden adatod elvész.";
    } else if (_languageProvider.isGerman) {
      return "Du bist mit einem Google-Konto angemeldet. Nach dem Löschen deines Kontos kannst du dich erneut registrieren, aber alle deine Daten gehen verloren.";
    } else {
      return "You are signed in with a Google account. After deleting your account, you can register again, but all your data will be lost.";
    }
  }

  static String get confirmDelete {
    if (_languageProvider.isHungarian) {
      return "Törlés megerősítése";
    } else if (_languageProvider.isGerman) {
      return "Löschen bestätigen";
    } else {
      return "Confirm Delete";
    }
  }

  static String get accountDeletionAuthError {
    if (_languageProvider.isHungarian) {
      return "Újra be kell jelentkezned a fiók törléséhez. Kérlek, erősítsd meg a Google-fiókodat.";
    } else if (_languageProvider.isGerman) {
      return "Sie müssen sich erneut anmelden, um Ihr Konto zu löschen. Bitte bestätigen Sie Ihr Google-Konto.";
    } else {
      return "You need to sign in again to delete your account. Please confirm your Google account.";
    }
  }

  static String get googleReauthNeeded {
    if (_languageProvider.isHungarian) {
      return "A megerősítéshez újra be kell jelentkezned a Google-fiókodba.";
    } else if (_languageProvider.isGerman) {
      return "Sie müssen sich erneut bei Ihrem Google-Konto anmelden, um dies zu bestätigen.";
    } else {
      return "You'll need to re-sign in to your Google account to confirm this.";
    }
  }

  static String get accountDeletedSuccessfully {
    if (_languageProvider.isHungarian) {
      return "Fiók sikeresen törölve!";
    } else if (_languageProvider.isGerman) {
      return "Konto erfolgreich gelöscht!";
    } else {
      return "Account successfully deleted!";
    }
  }
}
