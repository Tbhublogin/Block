import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// The app display name. Placeholder Arabic name — the final app name is not yet decided (see PROJECT_STATE.md open decisions).
  ///
  /// In ar, this message translates to:
  /// **'حضارات المكعبات'**
  String get appTitle;

  /// No description provided for @mainMenuPlay.
  ///
  /// In ar, this message translates to:
  /// **'العب'**
  String get mainMenuPlay;

  /// No description provided for @mainMenuMuseum.
  ///
  /// In ar, this message translates to:
  /// **'المتحف'**
  String get mainMenuMuseum;

  /// No description provided for @mainMenuSettings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get mainMenuSettings;

  /// No description provided for @underConstruction.
  ///
  /// In ar, this message translates to:
  /// **'قيد الإنشاء'**
  String get underConstruction;

  /// Display name of civilization #1 (Iraq / Mesopotamia) on the map screen; nameKey in civilizations_data.dart.
  ///
  /// In ar, this message translates to:
  /// **'الحضارة العراقية (بلاد الرافدين)'**
  String get civIraqName;

  /// Iraq landmark name (landmarkId: hanging_gardens); nameKey in civilizations_data.dart.
  ///
  /// In ar, this message translates to:
  /// **'حدائق بابل المعلقة'**
  String get landmarkHangingGardensName;

  /// Iraq landmark historical fact (landmarkId: hanging_gardens); historicalFactKey in civilizations_data.dart. Source: user-provided Arabic (Historical Text/text.txt), do not alter facts.
  ///
  /// In ar, this message translates to:
  /// **'حدائق بابل المعلقة هي أحد أشهر المعالم المنسوبة إلى الحضارة البابلية القديمة، ويُعتقد أنها شُيّدت في مدينة بابل خلال العصر البابلي الحديث (القرن السادس قبل الميلاد)، وترتبط تقليديًا بالملك نبوخذ نصر الثاني. وصفتها المصادر اليونانية القديمة بأنها حدائق مدرّجة ضخمة مليئة بالأشجار والنباتات، وكانت تُعد من عجائب العالم القديم السبع. ومع ذلك، لا يزال وجودها التاريخي محل نقاش بين الباحثين بسبب عدم العثور على دليل أثري حاسم يثبت موقعها أو شكلها النهائي.'**
  String get landmarkHangingGardensFact;

  /// Iraq landmark name (landmarkId: ziggurat_of_ur); nameKey in civilizations_data.dart.
  ///
  /// In ar, this message translates to:
  /// **'زقورة أور'**
  String get landmarkZigguratOfUrName;

  /// Iraq landmark historical fact (landmarkId: ziggurat_of_ur); historicalFactKey in civilizations_data.dart. Source: user-provided Arabic (Historical Text/text.txt), do not alter facts.
  ///
  /// In ar, this message translates to:
  /// **'يُظهر هذا المعلم الزقورة (Ziggurat) في مدينة أور القديمة، وهي من أبرز المنشآت الدينية في حضارة بلاد الرافدين السومرية. بُنيت الزقورة خلال الألف الثالث قبل الميلاد تقريباً في عهد سلالة أور الثالثة، وكانت مكرسة للإله نانّا (سين) إله القمر، وشكّلت مركزاً دينياً ورمزاً لقوة المدينة وتنظيمها الحضري. تميزت هذه الأبنية المدرّجة باستخدام الطوب اللَّبِن، وكانت تمثل حلقة وصل رمزية بين العالم الأرضي والعالم الإلهي في معتقدات سكان بلاد الرافدين.'**
  String get landmarkZigguratOfUrFact;

  /// Iraq landmark name (landmarkId: tower_of_babel); nameKey in civilizations_data.dart.
  ///
  /// In ar, this message translates to:
  /// **'برج بابل'**
  String get landmarkTowerOfBabelName;

  /// Iraq landmark historical fact (landmarkId: tower_of_babel); historicalFactKey in civilizations_data.dart. Source: user-provided Arabic (Historical Text/text.txt), do not alter facts.
  ///
  /// In ar, this message translates to:
  /// **'برج بابل هو بناء أسطوري ورد ذكره في سفر التكوين ضمن التقاليد الدينية القديمة، حيث يُقال إن البشر شيدوا برجًا عظيمًا يصل إلى السماء في أرض شنعار (بلاد الرافدين)، فارتبطت قصته بمحاولة الإنسان بلوغ مكانة إلهية، وبقصة تبلبل اللغات بين البشر. لا توجد أدلة أثرية مؤكدة تثبت وجود برج بابل كما وُصف في الرواية، لكن يُعتقد أن القصة قد تكون مستوحاة من الزقورات الرافدية، وهي معابد مدرّجة ضخمة بنتها حضارات مثل السومريين والبابليين خلال الألفية الثالثة والثانية قبل الميلاد. أصبح برج بابل رمزًا عالميًا للطموح البشري، والعمارة الضخمة، وتنوع الثقافات واللغات.'**
  String get landmarkTowerOfBabelFact;

  /// Iraq landmark name (landmarkId: hammurabi_stele); nameKey in civilizations_data.dart.
  ///
  /// In ar, this message translates to:
  /// **'مسلة حمورابي'**
  String get landmarkHammurabiSteleName;

  /// Iraq landmark historical fact (landmarkId: hammurabi_stele); historicalFactKey in civilizations_data.dart. Source: user-provided Arabic (Historical Text/text.txt), do not alter facts.
  ///
  /// In ar, this message translates to:
  /// **'هذا الأثر هو مسلة حمورابي، إحدى أشهر آثار الحضارة البابلية القديمة، وتعود إلى عهد الملك حمورابي الذي حكم بابل تقريباً بين (1792–1750 ق.م). نُقشت عليها مجموعة من القوانين التي تُعد من أقدم المدونات القانونية المكتوبة في التاريخ، وتُظهر الصورة في أعلاها مشهداً رمزياً لحمورابي وهو يتلقى السلطة أو التشريع من الإله شمش، إله العدل في بلاد الرافدين. تمثل المسلة أهمية كبيرة لفهم نظام الحكم والقضاء والمجتمع في الدولة البابلية، وهي محفوظة حالياً في متحف اللوفر.'**
  String get landmarkHammurabiSteleFact;

  /// Iraq landmark name (landmarkId: ishtar_gate); nameKey in civilizations_data.dart.
  ///
  /// In ar, this message translates to:
  /// **'بوابة عشتار'**
  String get landmarkIshtarGateName;

  /// Iraq landmark historical fact (landmarkId: ishtar_gate); historicalFactKey in civilizations_data.dart. Source: user-provided Arabic (Historical Text/text.txt), do not alter facts.
  ///
  /// In ar, this message translates to:
  /// **'بوابة عشتار هي إحدى أشهر معالم مدينة بابل القديمة، شُيّدت في عهد الملك البابلي نبوخذ نصر الثاني خلال القرن السادس قبل الميلاد (نحو 575 ق.م) ضمن مشروعه لتوسعة وتجميل عاصمة الإمبراطورية البابلية الحديثة. كانت البوابة مكرّسة للإلهة عشتار، وزُيّنت بآجر أزرق لامع مزجج ونقوش بارزة لحيوانات مقدسة مثل الأسود والثيران والمخلوقات الأسطورية، وكانت تمثل المدخل الاحتفالي لطريق الموكب المؤدي إلى معبد مردوخ. تُعد اليوم من أبرز الشواهد على تقدم العمارة والفنون البابلية القديمة.'**
  String get landmarkIshtarGateFact;

  /// Iraq landmark name (landmarkId: lamassu); nameKey in civilizations_data.dart.
  ///
  /// In ar, this message translates to:
  /// **'اللاماسو الآشوري'**
  String get landmarkLamassuName;

  /// Iraq landmark historical fact (landmarkId: lamassu); historicalFactKey in civilizations_data.dart. Source: user-provided Arabic (Historical Text/text.txt), do not alter facts.
  ///
  /// In ar, this message translates to:
  /// **'اللاماسو الآشوري (Lamassu) هو تمثال حارس مجنّح من حضارة آشور القديمة، يعود بشكل خاص إلى فترة الإمبراطورية الآشورية الحديثة (القرن التاسع–السابع قبل الميلاد). كان اللاماسو يُوضع عند مداخل القصور والمعابد، مثل قصور ملوك آشور في نمرود وخورسباد ونينوى، اعتقادًا بأنه يحمي المبنى وسكانه من القوى الشريرة. يجمع التمثال بين جسد الثور أو الأسد، وأجنحة الطيور، ورأس الإنسان ذي اللحية والتاج، في رمز يجمع القوة والحكمة والسلطة الملكية الآشورية.'**
  String get landmarkLamassuFact;

  /// Iraq landmark name (landmarkId: golden_lyre_of_ur); nameKey in civilizations_data.dart.
  ///
  /// In ar, this message translates to:
  /// **'القيثارة الذهبية (قيثارة أور)'**
  String get landmarkGoldenLyreOfUrName;

  /// Iraq landmark historical fact (landmarkId: golden_lyre_of_ur); historicalFactKey in civilizations_data.dart. Source: user-provided Arabic (Historical Text/text.txt), do not alter facts.
  ///
  /// In ar, this message translates to:
  /// **'القيثارة ذات رأس الثور هي آلة موسيقية أثرية عُثر على نماذج شهيرة منها في مدينة أور السومرية جنوب بلاد الرافدين، وتعود إلى نحو منتصف الألف الثالث قبل الميلاد (العصر السومري المبكر). صُنعت من الخشب وزُيّنت بالذهب والأحجار الكريمة والعاج، وكان رأس الثور يرمز إلى القوة والخصوبة ويرتبط بالرموز الدينية في حضارة بلاد الرافدين. استُخدمت هذه القيثارات في الطقوس الدينية والاحتفالات الملكية، وتُعد من أقدم الأدلة على تطور الموسيقى وصناعة الآلات الوترية في التاريخ.'**
  String get landmarkGoldenLyreOfUrFact;

  /// Iraq landmark name (landmarkId: naram_sin_stele); nameKey in civilizations_data.dart.
  ///
  /// In ar, this message translates to:
  /// **'مسلة نرام سين (نصب النصر الأكدي)'**
  String get landmarkNaramSinSteleName;

  /// Iraq landmark historical fact (landmarkId: naram_sin_stele); historicalFactKey in civilizations_data.dart. Source: user-provided Arabic (Historical Text/text.txt), do not alter facts.
  ///
  /// In ar, this message translates to:
  /// **'هذه الصورة تمثل نصب النصر الأكدي (مسلة النصر) المنسوب إلى الملك نرام سين (Naram-Sin) من الإمبراطورية الأكدية، التي ازدهرت في بلاد الرافدين خلال القرن الثالث والعشرين قبل الميلاد تقريباً. تُظهر المسلة الملك نرام سين في هيئة بطولية وهو يقود جيشه في معركة ضد أعدائه، مع رموز سماوية في الأعلى تشير إلى التأييد الإلهي للملك. تُعد هذه القطعة من أهم الأعمال الفنية في تاريخ بلاد الرافدين، إذ تُظهر تطور فن النحت السردي واستخدام الفن لتوثيق انتصارات الملوك وتعزيز مكانتهم السياسية والدينية.'**
  String get landmarkNaramSinSteleFact;

  /// Iraq landmark name (landmarkId: cuneiform_tablet); nameKey in civilizations_data.dart.
  ///
  /// In ar, this message translates to:
  /// **'اللوح الطيني المسماري'**
  String get landmarkCuneiformTableName;

  /// Iraq landmark historical fact (landmarkId: cuneiform_tablet); historicalFactKey in civilizations_data.dart. Source: user-provided Arabic (Historical Text/text.txt), do not alter facts.
  ///
  /// In ar, this message translates to:
  /// **'هذه الصورة تمثل لوحًا طينيًا مكتوبًا بالخط المسماري من حضارات بلاد الرافدين القديمة، حيث استُخدمت الألواح الطينية لتسجيل النصوص الإدارية والأدبية والقانونية والعلمية منذ الألف الثالث قبل الميلاد. كان الكتبة السومريون ثم الأكديون والبابليون والآشوريون ينقشون الرموز المسمارية على الطين الطري باستخدام أداة قصبية مدببة، ثم تُجفف الألواح أو تُحرق لحفظها. تمثل هذه الألواح أحد أهم إنجازات الحضارة الرافدية، إذ حفظت لنا معلومات عن الحياة اليومية، والعلوم، والأساطير، وأنظمة الحكم في أقدم المدن المتحضرة في التاريخ.'**
  String get landmarkCuneiformTabletFact;

  /// Iraq landmark name (landmarkId: lion_of_babylon); nameKey in civilizations_data.dart.
  ///
  /// In ar, this message translates to:
  /// **'أسد بابل'**
  String get landmarkLionOfBabylonName;

  /// Iraq landmark historical fact (landmarkId: lion_of_babylon); historicalFactKey in civilizations_data.dart. Source: user-provided Arabic (Historical Text/text.txt), do not alter facts.
  ///
  /// In ar, this message translates to:
  /// **'يُعرف هذا المعلم باسم أسد بابل، وهو تمثال حجري منحوت يعود إلى العصر البابلي الحديث في عهد الملك نبوخذ نصر الثاني (القرن السادس قبل الميلاد تقريباً). يقع في مدينة بابل الأثرية في العراق، ويُجسّد أسدًا يعلو جسد رجل، ويرمز إلى قوة الدولة البابلية وهيبتها، كما ارتبط برموز السلطة والسيطرة في الفن البابلي. يُعد أسد بابل من أبرز الشواهد الفنية التي تعكس مهارة النحاتين البابليين واستخدامهم للنحت الحجري للتعبير عن القوة الملكية والدينية.'**
  String get landmarkLionOfBabylonFact;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
