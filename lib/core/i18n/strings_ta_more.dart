/// Tamil translations, part 2: roster, analytics, sign-up, pay rules, swaps and
/// date words. Keyed by the English text.
const tamilStringsMore = <String, String>{
  // Dates and times
  'Mon': 'திங்',
  'Tue': 'செவ்',
  'Wed': 'புத',
  'Thu': 'வியா',
  'Fri': 'வெள்',
  'Sat': 'சனி',
  'Sun': 'ஞாயி',
  'Jan': 'ஜன',
  'Feb': 'பிப்',
  'Mar': 'மார்',
  'Apr': 'ஏப்',
  'May': 'மே',
  'Jun': 'ஜூன்',
  'Jul': 'ஜூலை',
  'Aug': 'ஆக',
  'Sep': 'செப்',
  'Oct': 'அக்',
  'Nov': 'நவ',
  'Dec': 'டிச',
  '{n} min': '{n} நிமி',
  '{n} h': '{n} மணி',
  '{t} ago': '{t} முன்பு',
  'in {t}': '{t} இல்',
  'Days': 'நாட்கள்',
  'days taken': 'நாட்கள் எடுக்கப்பட்டன',

  // Duty steps
  'Check in': 'வருகை பதிவு',
  'Check-in done': 'வருகை பதிவானது',
  'Signed in at {time}': '{time} இல் வருகை',
  'Starts {when} · {time}': '{when} தொடங்கும் · {time}',
  'Shift started at {time}': 'பணி {time} இல் தொடங்கியது',
  'Main shift done': 'முதன்மைப் பணி முடிந்தது',
  'Signed out at {time}': '{time} இல் வெளியேறினார்',
  'Main shift ending': 'முதன்மைப் பணி முடிகிறது',
  'Main shift ended': 'முதன்மைப் பணி முடிந்தது',
  'Ended {time} · sign out': '{time} இல் முடிந்தது · வெளியேறு',
  'Ends at {time}': '{time} இல் முடியும்',
  'OT done': 'OT முடிந்தது',
  '{hours} hrs logged': '{hours} மணிநேரம் பதிவானது',
  'OT in progress': 'OT நடைபெறுகிறது',
  'Started at {time}': '{time} இல் தொடங்கியது',
  'Started {time}': '{time} இல் தொடங்கியது',
  'OT starts automatically': 'OT தானாகத் தொடங்கும்',
  'at {time} · {hours} hrs, no sign-out needed':
      '{time} இல் · {hours} மணிநேரம், வெளியேறத் தேவையில்லை',
  'OT shift starting': 'OT பணி தொடங்குகிறது',
  'at {time} · {hours} hrs': '{time} இல் · {hours} மணிநேரம்',
  'OT (optional)': 'OT (விரும்பினால்)',
  'Switch to OT when you sign out': 'வெளியேறும்போது OT க்கு மாறுங்கள்',
  'OT starts after {hours} hrs': '{hours} மணிநேரத்துக்குப் பின் OT தொடங்கும்',
  "Today's Shift": 'இன்றைய பணி',
  "This Month's\nPredicted Salary": 'இந்த மாதத்தின்\nகணிக்கப்பட்ட சம்பளம்',

  // Sleep day, swaps, holidays
  'Sleep day': 'உறக்க நாள்',
  'Rest after your night duty. No duty today.':
      'இரவுப் பணிக்குப் பின் ஓய்வெடுங்கள். இன்று பணி இல்லை.',
  'Your night duty ends at 07:00 this morning. This duty starts straight after it, with no sleep.':
      'உங்கள் இரவுப் பணி இன்று காலை 07:00 க்கு முடிகிறது. இந்தப் பணி உறக்கம் இல்லாமல் அதன் பின் உடனே தொடங்குகிறது.',
  'Swap with a colleague': 'சக ஊழியருடன் மாற்று',
  "Colleague's name": 'சக ஊழியரின் பெயர்',
  'I take one of their duties': 'அவர்களின் ஒரு பணியை நான் ஏற்கிறேன்',
  'Swap': 'மாற்று',
  'Swapped': 'மாற்றப்பட்டது',
  'Duty swapped': 'பணி மாற்றப்பட்டது',
  'Duty swapped with {name}': '{name} உடன் பணி மாற்றப்பட்டது',
  'Given to {name}': '{name} க்கு வழங்கப்பட்டது',
  'Given to {name} in a duty swap': 'பணி மாற்றத்தில் {name} க்கு வழங்கப்பட்டது',
  'Swapped to a colleague': 'சக ஊழியருக்கு மாற்றப்பட்டது',
  'Public holiday duty': 'பொது விடுமுறைப் பணி',
  'Marked as public holiday duty': 'பொது விடுமுறைப் பணியாகக் குறிக்கப்பட்டது',
  'Public holiday removed': 'பொது விடுமுறை நீக்கப்பட்டது',
  'Sunday duty is counted automatically': 'ஞாயிறு பணி தானாகக் கணக்கிடப்படும்',
  'Earns the holiday rate set in Pay rules':
      'சம்பள விதிகளில் அமைக்கப்பட்ட விடுமுறைக் கட்டணம் கிடைக்கும்',

  // Pay rules
  'Pay rules': 'சம்பள விதிகள்',
  'Pay rules saved': 'சம்பள விதிகள் சேமிக்கப்பட்டன',
  'Save pay rules': 'சம்பள விதிகளைச் சேமி',
  "Defaults follow common government practice. Hospitals differ, so check these with your hospital and change any that don't match.":
      'இயல்புநிலைகள் வழக்கமான அரச நடைமுறையைப் பின்பற்றுகின்றன. மருத்துவமனைகள் வேறுபடுவதால், உங்கள் மருத்துவமனையுடன் சரிபார்த்து பொருந்தாதவற்றை மாற்றுங்கள்.',
  'Employer': 'பணியிடம்',
  'Government': 'அரசு',
  'Private': 'தனியார்',
  "Private hospitals usually pay a fixed OT hourly rate: set it under Pay settings. Remove COLA and W&OP there if they don't apply to you.":
      'தனியார் மருத்துவமனைகள் பொதுவாக நிலையான OT மணிநேரக் கட்டணம் செலுத்துகின்றன: அதை சம்பள அமைப்புகளில் அமைக்கவும். COLA மற்றும் W&OP உங்களுக்குப் பொருந்தாவிட்டால் அங்கே நீக்கவும்.',
  'Salary grade': 'சம்பளத் தரம்',
  'Grade': 'தரம்',
  'Salary step (increments)': 'சம்பளப் படி (அதிகரிப்புகள்)',
  'Basic salary at this step: {amount}':
      'இந்தப் படியில் அடிப்படைச் சம்பளம்: {amount}',
  'Saving replaces your current basic of {amount}.':
      'சேமித்தால் உங்கள் தற்போதைய அடிப்படை {amount} மாற்றப்படும்.',
  'How OT is counted': 'OT எப்படிக் கணக்கிடப்படுகிறது',
  'Per duty': 'பணிக்கு',
  'OT recorded on each duty (after the main shift, or the extra hours of a D / 24 duty).':
      'ஒவ்வொரு பணியிலும் பதிவான OT (முதன்மைப் பணிக்குப் பின், அல்லது D / 24 பணியின் கூடுதல் மணிநேரம்).',
  'From monthly hours': 'மாதாந்த மணிநேரத்திலிருந்து',
  'Every hour worked in the month beyond the required duty hours is OT.':
      'தேவையான பணி மணிநேரத்துக்கு மேல் மாதத்தில் பணியாற்றிய ஒவ்வொரு மணிநேரமும் OT.',
  'Required hours a month': 'மாதத்துக்குத் தேவையான மணிநேரம்',
  'Hourly rate divisor': 'மணிநேரக் கட்டண வகுப்பான்',
  'Basic salary ÷ this = basic hourly rate':
      'அடிப்படைச் சம்பளம் ÷ இது = அடிப்படை மணிநேரக் கட்டணம்',
  'Sunday & public holiday duty': 'ஞாயிறு & பொது விடுமுறைப் பணி',
  'Extra pay for each main-shift hour, as a multiple of the basic hourly rate.':
      'ஒவ்வொரு முதன்மைப் பணி மணிநேரத்துக்கும் கூடுதல் கொடுப்பனவு, அடிப்படை மணிநேரக் கட்டணத்தின் மடங்காக.',
  'Off': 'முடக்கம்',
  'Sundays count as holidays': 'ஞாயிறுகள் விடுமுறையாகக் கணக்கிடப்படும்',
  'Mark public holidays on the duty itself (Public holiday duty).':
      'பொது விடுமுறையைப் பணியிலேயே குறியுங்கள் (பொது விடுமுறைப் பணி).',
  'Leave entitlements (days a year)': 'விடுப்பு உரிமைகள் (ஆண்டுக்கு நாட்கள்)',
  '0 = no fixed quota': '0 = நிலையான வரம்பு இல்லை',
  'Decrease': 'குறை',
  'Increase': 'கூட்டு',
  'Leave 0 to use basic ÷ {divisor} × multiplier':
      'அடிப்படை ÷ {divisor} × பெருக்கி பயன்படுத்த 0 என விடுக',
  'Auto · {amount}': 'தானியங்கி · {amount}',
  'Connected to {server}': '{server} உடன் இணைக்கப்பட்டது',

  // Roster screens
  'Manual Roster': 'கைமுறை அட்டவணை',
  'How to add your roster': 'உங்கள் அட்டவணையைச் சேர்ப்பது எப்படி',
  'Tap a day to set its shift': 'பணியை அமைக்க ஒரு நாளைத் தொடுங்கள்',
  'Fill rota': 'சுழற்சியை நிரப்பு',
  'Fill with rota': 'சுழற்சியால் நிரப்பு',
  'Fill': 'நிரப்பு',
  'Start on day': 'தொடக்க நாள்',
  'No changes': 'மாற்றங்கள் இல்லை',
  'Not set': 'அமைக்கப்படவில்லை',
  'Double shift · edit from Duty details':
      'இரட்டைப் பணி · பணி விவரங்களில் திருத்து',
  'Change shift': 'பணியை மாற்று',
  'Clear day': 'நாளை அழி',
  'Next month': 'அடுத்த மாதம்',
  'Previous month': 'முந்தைய மாதம்',
  'Day duty, 12 h': 'பகல் பணி, 12 மணி',
  'Short duty, 8 h': 'குறுகிய பணி, 8 மணி',
  'Absent': 'வராதது',
  'Type your duty roster day by day. It takes about a minute for a whole month.':
      'உங்கள் பணி அட்டவணையை நாள்தோறும் உள்ளிடுங்கள். முழு மாதத்துக்கும் சுமார் ஒரு நிமிடம் ஆகும்.',
  'Pick the month': 'மாதத்தைத் தேர்ந்தெடுங்கள்',
  'Use ‹ › at the top. You can go up to 3 months back or ahead.':
      'மேலே உள்ள ‹ › ஐப் பயன்படுத்துங்கள். 3 மாதங்கள் பின்னோ முன்னோ செல்லலாம்.',
  'Set each day': 'ஒவ்வொரு நாளையும் அமையுங்கள்',
  'Tap the code badge on the right of a day and choose its duty, leave or day off. Choose “Clear day” to remove it.':
      'ஒரு நாளின் வலப்புறக் குறியீட்டைத் தொட்டு அதன் பணி, விடுப்பு அல்லது ஓய்வு நாளைத் தேர்ந்தெடுங்கள். நீக்க “நாளை அழி” என்பதைத் தேர்ந்தெடுங்கள்.',
  'Fill a whole month fast': 'முழு மாதத்தையும் விரைவாக நிரப்புங்கள்',
  '“Fill rota” fills empty days with 7 7 1 1 N N DO, starting on the day you pick. Days you already set are never overwritten.':
      '“சுழற்சியை நிரப்பு” நீங்கள் தேர்ந்தெடுக்கும் நாளிலிருந்து வெற்று நாட்களை 7 7 1 1 N N DO என நிரப்பும். ஏற்கனவே அமைத்த நாட்கள் ஒருபோதும் மாற்றப்படாது.',
  'Changed days get a purple dot. Tap “Save” at the bottom to keep them; leaving without saving discards them.':
      'மாற்றிய நாட்களுக்கு ஊதா புள்ளி வரும். அவற்றை வைத்திருக்கக் கீழே “சேமி” என்பதைத் தொடுங்கள்; சேமிக்காமல் வெளியேறினால் அவை இழக்கப்படும்.',
  'Locked days': 'பூட்டிய நாட்கள்',
  'A day with more than one entry (e.g. Morning + Evening) is locked here. Change it from Duty & Roster details instead.':
      'ஒன்றுக்கு மேற்பட்ட பதிவுகள் உள்ள நாள் (எ.கா. காலை + மாலை) இங்கே பூட்டப்பட்டுள்ளது. அதற்குப் பதிலாக பணி & அட்டவணை விவரங்களில் மாற்றுங்கள்.',
  'Duty codes': 'பணிக் குறியீடுகள்',
  'The same codes as your ward roster.':
      'உங்கள் வார்டு அட்டவணையில் உள்ள அதே குறியீடுகள்.',
  'D and 24 duties include their OT automatically (6 h + 6 h and 6 h + 18 h). Have a photo of the roster? Use Scan Roster instead and fix only what it misreads.':
      'D மற்றும் 24 பணிகளில் OT தானாகச் சேரும் (6 + 6 மற்றும் 6 + 18 மணி). அட்டவணையின் படம் உள்ளதா? அட்டவணையை ஸ்கேன் செய் பயன்படுத்தி தவறாகப் படித்ததை மட்டும் திருத்துங்கள்.',
  'Got it': 'புரிந்தது',
  'Scan Roster': 'அட்டவணையை ஸ்கேன் செய்',
  'Roster month': 'அட்டவணை மாதம்',
  'Take photo': 'படம் எடு',
  'From gallery': 'கேலரியிலிருந்து',
  'Paste roster text instead': 'அதற்குப் பதில் அட்டவணை உரையை ஒட்டு',
  'Paste roster text': 'அட்டவணை உரையை ஒட்டு',
  "Text from your phone's text scanner works too":
      'உங்கள் தொலைபேசியின் உரை ஸ்கேனரின் உரையும் வேலை செய்யும்',
  'Read': 'படி',
  'Your name as printed (optional)': 'அச்சிடப்பட்ட உங்கள் பெயர் (விரும்பினால்)',
  'For ward rosters with one row per nurse, e.g. "K. PERERA"':
      'தாதிக்கு ஒரு வரிசை உள்ள வார்டு அட்டவணைகளுக்கு, எ.கா. "K. PERERA"',
  'For a clean read': 'தெளிவான வாசிப்புக்கு',
  'Lay the roster flat in good light':
      'அட்டவணையை நல்ல ஒளியில் தட்டையாக வையுங்கள்',
  'Fill the frame and hold the phone straight':
      'சட்டகத்தை நிரப்பி தொலைபேசியை நேராகப் பிடியுங்கள்',
  'Include the row of day numbers': 'நாள் எண்களின் வரிசையைச் சேருங்கள்',
  'Reading your {month} roster…': 'உங்கள் {month} அட்டவணையைப் படிக்கிறது…',
  'Review Roster': 'அட்டவணையை மீளாய்வு செய்',
  'All clear': 'அனைத்தும் சரி',
  'Needs a look': 'பார்க்க வேண்டும்',
  'Tap a code to change it. Swipe a row away to drop it.':
      'மாற்ற ஒரு குறியீட்டைத் தொடுங்கள். நீக்க ஒரு வரிசையை ஸ்வைப் செய்யுங்கள்.',
  'Replace days I already entered': 'நான் ஏற்கனவே உள்ளிட்ட நாட்களை மாற்று',
  'Set': 'அமை',
  'Nothing could be read from this photo. Go back and try a clearer, well-lit shot.':
      'இந்தப் படத்திலிருந்து எதையும் படிக்க முடியவில்லை. பின் சென்று தெளிவான, நல்ல ஒளியுள்ள படத்தை முயலுங்கள்.',
  'Read as "{code}"': '"{code}" எனப் படிக்கப்பட்டது',
  'Read as "{code}" · please check':
      '"{code}" எனப் படிக்கப்பட்டது · சரிபார்க்கவும்',

  // Analytics
  'Projected take-home': 'கணிக்கப்பட்ட நிகரச் சம்பளம்',
  'Likely {low} – {high}': 'பெரும்பாலும் {low} – {high}',
  'Roster alone gives {amount}; the forecast adds your usual extra OT and absences.':
      'அட்டவணை மட்டும் {amount} தருகிறது; கணிப்பு உங்கள் வழக்கமான கூடுதல் OT மற்றும் வராமைகளைச் சேர்க்கிறது.',
  'Earned so far': 'இதுவரை ஈட்டியது',
  'Basic (so far)': 'அடிப்படை (இதுவரை)',
  'Overtime': 'மேலதிக நேரம்',
  'Allowances': 'கொடுப்பனவுகள்',
  'OT this month': 'இந்த மாத OT',
  'Rostered': 'அட்டவணையில்',
  'Likely extra': 'பெரும்பாலும் கூடுதல்',
  'Likely {low}–{high} hrs': 'பெரும்பாலும் {low}–{high} மணிநேரம்',
  'Your usual month: {hours} hrs of OT':
      'உங்கள் வழக்கமான மாதம்: {hours} மணிநேர OT',
  'OT by weekday': 'வார நாள் வாரியாக OT',
  'OT habit:': 'OT பழக்கம்:',
  'Smart forecast': 'ஸ்மார்ட் கணிப்பு',
  'Your plan shows a roster-based estimate. Upgrade to add your usual extra OT, absences and a confidence score.':
      'உங்கள் திட்டம் அட்டவணை அடிப்படையிலான மதிப்பீட்டைக் காட்டுகிறது. உங்கள் வழக்கமான கூடுதல் OT, வராமைகள் மற்றும் நம்பகத்தன்மை மதிப்பெண்ணைச் சேர்க்க மேம்படுத்துங்கள்.',
  'Payslip preview': 'சம்பளச் சீட்டு முன்னோட்டம்',
  'Gross': 'மொத்தம்',
  'Deductions': 'கழிவுகள்',
  'Fixed deductions': 'நிலையான கழிவுகள்',
  'No-pay deductions': 'சம்பளமில்லாக் கழிவுகள்',
  'Net (LKR)': 'நிகரம் (ரூ.)',
  'How is this calculated?': 'இது எப்படிக் கணக்கிடப்படுகிறது?',
  'Confidence factors': 'நம்பகத்தன்மைக் காரணிகள்',
  'Month already worked': 'ஏற்கனவே பணியாற்றிய மாதம்',
  'Roster filled in': 'அட்டவணை நிரப்பப்பட்டது',
  'OT consistency': 'OT நிலைத்தன்மை',
  'History available': 'கிடைக்கும் வரலாறு',
  'Workload & wellbeing': 'பணிச்சுமை & நலன்',
  'Workload & burnout insights': 'பணிச்சுமை & சோர்வு பற்றிய தகவல்',
  'Shift mix, weekly hours and burnout risk are part of a higher plan.':
      'பணிக் கலவை, வாராந்த மணிநேரம் மற்றும் சோர்வு அபாயம் உயர் திட்டத்தின் பகுதி.',
  'Burnout risk': 'சோர்வு அபாயம்',
  'Your recent workload looks balanced. Keep it up!':
      'உங்கள் சமீபத்திய பணிச்சுமை சமநிலையாக உள்ளது. தொடருங்கள்!',
  'Shift mix · last 3 months': 'பணிக் கலவை · கடந்த 3 மாதங்கள்',
  'Off-day OT': 'ஓய்வு நாள் OT',
  'Avg. weekly': 'வாராந்தச் சராசரி',
  'OT share': 'OT பங்கு',
  'OT rising': 'OT அதிகரிக்கிறது',
  'OT falling': 'OT குறைகிறது',
  'OT steady': 'OT நிலையானது',
  'These figures use a typical nursing salary. Add yours for exact predictions.':
      'இந்த எண்கள் வழக்கமான தாதிச் சம்பளத்தைப் பயன்படுத்துகின்றன. துல்லியமான கணிப்புக்கு உங்கள் சம்பளத்தைச் சேர்க்கவும்.',
  'Week of {day}': '{day} வாரம்',
  'Main {hours}h': 'முதன்மை {hours} மணி',
  'This month so far: {ot} OT · {night} night allowance':
      'இந்த மாதம் இதுவரை: OT {ot} · இரவுக் கொடுப்பனவு {night}',

  // Onboarding
  'Make your salary exact': 'உங்கள் சம்பளத்தைத் துல்லியமாக்குங்கள்',
  'To calculate your exact salary & OT predictions, please enter your Base Salary & Hourly OT Rate.':
      'உங்கள் துல்லியமான சம்பளம் & OT கணிப்புக்கு, உங்கள் அடிப்படைச் சம்பளம் & OT மணிநேரக் கட்டணத்தை உள்ளிடுங்கள்.',
  'Base salary (LKR / month)': 'அடிப்படைச் சம்பளம் (ரூ. / மாதம்)',
  'OT rate (LKR / hour)': 'OT கட்டணம் (ரூ. / மணி)',
  'Optional. Leave empty to use basic ÷ 240 × 1.5':
      'விரும்பினால். அடிப்படை ÷ 240 × 1.5 பயன்படுத்த வெறுமையாக விடுக',
  'Save & predict': 'சேமித்துக் கணி',
  'Skip for now (Use Default Estimate)': 'இப்போது தவிர் (இயல்புநிலை மதிப்பீடு)',
  'Salary saved. Predictions are now exact':
      'சம்பளம் சேமிக்கப்பட்டது. கணிப்புகள் இப்போது துல்லியம்',
  'Using a typical salary estimate for now':
      'தற்போதைக்கு வழக்கமான சம்பள மதிப்பீடு',
  'Estimate · add your salary': 'மதிப்பீடு · உங்கள் சம்பளத்தைச் சேருங்கள்',
  'Enter your basic salary': 'உங்கள் அடிப்படைச் சம்பளத்தை உள்ளிடுக',
  'Enter an amount in LKR': 'ரூபாயில் ஒரு தொகையை உள்ளிடுக',
  'That looks too high': 'அது மிக அதிகமாகத் தெரிகிறது',
  'Which ward?': 'எந்த வார்டு?',
  'Select your primary hospital':
      'உங்கள் முதன்மை மருத்துவமனையைத் தேர்ந்தெடுங்கள்',
  'Search hospitals': 'மருத்துவமனைகளைத் தேடு',
  'Use "{name}"': '"{name}" ஐப் பயன்படுத்து',
  'Ward number (optional)': 'வார்டு எண் (விரும்பினால்)',
  'Optional. Helps match your roster rows.':
      'விரும்பினால். உங்கள் அட்டவணை வரிசைகளைப் பொருத்த உதவும்.',
  'We use it to label your roster. You can change it any time.':
      'உங்கள் அட்டவணையைப் பெயரிட இதைப் பயன்படுத்துகிறோம். எப்போது வேண்டுமானாலும் மாற்றலாம்.',
  'Save & continue': 'சேமித்துத் தொடர்',
  'Skip': 'தவிர்',
  'Never miss a shift': 'எந்தப் பணியையும் தவறவிடாதீர்கள்',
  'Turn on reminders': 'நினைவூட்டல்களை இயக்கு',
  'Not now': 'இப்போது இல்லை',
  'Notifications are blocked. You can turn them on later in Profile.':
      'அறிவிப்புகள் தடுக்கப்பட்டுள்ளன. பின்னர் சுயவிவரத்தில் இயக்கலாம்.',

  // Sign up and validation
  'Create your account': 'உங்கள் கணக்கை உருவாக்குங்கள்',
  'Takes 10 seconds. Pay and ward details can wait until you need them.':
      '10 விநாடிகள் ஆகும். சம்பளம் மற்றும் வார்டு விவரங்கள் தேவைப்படும் வரை காத்திருக்கலாம்.',
  'Your name': 'உங்கள் பெயர்',
  'Create account': 'கணக்கை உருவாக்கு',
  "No salary or ward details needed now: we'll ask only when a feature needs them.":
      'இப்போது சம்பளம் அல்லது வார்டு விவரங்கள் தேவையில்லை: ஒரு வசதிக்குத் தேவைப்படும்போது மட்டுமே கேட்போம்.',
  'Required': 'தேவை',
  'Enter a valid email': 'சரியான மின்னஞ்சலை உள்ளிடுக',
  'At least 8 characters': 'குறைந்தது 8 எழுத்துகள்',
  'At most 72 characters': 'அதிகபட்சம் 72 எழுத்துகள்',
  'Use letters and numbers': 'எழுத்துகளையும் எண்களையும் பயன்படுத்துங்கள்',
  'Enter an email or a mobile like 077 123 4567':
      'மின்னஞ்சல் அல்லது 077 123 4567 போன்ற கைபேசி எண்ணை உள்ளிடுக',
  'Enter your email or mobile number':
      'உங்கள் மின்னஞ்சல் அல்லது கைபேசி எண்ணை உள்ளிடுக',
  'Enter your email': 'உங்கள் மின்னஞ்சலை உள்ளிடுக',

  // Google sign-in
  'Use email or mobile': 'மின்னஞ்சல் அல்லது கைபேசியைப் பயன்படுத்து',
  "Google sign-in didn't work. Please try again or use your email/mobile.":
      'Google உள்நுழைவு வேலை செய்யவில்லை. மீண்டும் முயலுங்கள் அல்லது உங்கள் மின்னஞ்சல்/கைபேசியைப் பயன்படுத்துங்கள்.',
  'You used Google last time':
      'கடந்த முறை நீங்கள் Google ஐப் பயன்படுத்தினீர்கள்',
  'Fastest: one tap, no password': 'மிக விரைவு: ஒரே தொடுதல், கடவுச்சொல் இல்லை',

  // App guide
  'Welcome': 'வருக',
  'What is Nurse Companion?': 'Nurse Companion என்றால் என்ன?',
  'A personal assistant for nurses in Sri Lanka. It keeps your duty roster, overtime, leave and salary together in one place, and does the counting for you.':
      'இலங்கைத் தாதியருக்கான தனிப்பட்ட உதவியாளர். உங்கள் பணி அட்டவணை, மேலதிக நேரம், விடுப்பு மற்றும் சம்பளத்தை ஒரே இடத்தில் வைத்து, கணக்குகளை உங்களுக்காகச் செய்கிறது.',
  'Your duty roster for the whole month':
      'முழு மாதத்துக்கான உங்கள் பணி அட்டவணை',
  'Every OT hour, counted correctly':
      'ஒவ்வொரு OT மணிநேரமும் சரியாகக் கணக்கிடப்படும்',
  'Leave taken and leave remaining': 'எடுத்த மற்றும் மீதமுள்ள விடுப்பு',
  'Your salary, before payday': 'சம்பள நாளுக்கு முன்பே உங்கள் சம்பளம்',
  'Why use it': 'ஏன் பயன்படுத்த வேண்டும்',
  'Less paperwork. No missed pay.':
      'குறைந்த காகித வேலை. தவறும் கொடுப்பனவு இல்லை.',
  'Most nurses track duties in a notebook and work out OT by hand. Mistakes mean lost money. Nurse Companion records everything as you work.':
      'பெரும்பாலான தாதியர் பணிகளை நோட்டுப் புத்தகத்தில் எழுதி OT ஐக் கையால் கணக்கிடுகின்றனர். தவறுகள் பண இழப்பாகும். Nurse Companion நீங்கள் பணியாற்றும்போதே அனைத்தையும் பதிவு செய்கிறது.',
  'No more notebooks or calculators':
      'இனி நோட்டுப் புத்தகமோ கால்குலேட்டரோ தேவையில்லை',
  'OT on D and 24 duties is counted automatically':
      'D மற்றும் 24 பணிகளில் OT தானாகக் கணக்கிடப்படும்',
  'Night allowance and holiday duty are not forgotten':
      'இரவுக் கொடுப்பனவும் விடுமுறைப் பணியும் மறக்கப்படாது',
  'Check your payslip against your own record':
      'உங்கள் சம்பளச் சீட்டை உங்கள் சொந்தப் பதிவுடன் சரிபாருங்கள்',
  'Step 1 · Once a month': 'படி 1 · மாதத்துக்கு ஒருமுறை',
  'Add your duty roster': 'உங்கள் பணி அட்டவணையைச் சேருங்கள்',
  'Take a photo of your ward roster and the app reads it, or type it day by day with the same codes your ward uses. A month takes about a minute.':
      'உங்கள் வார்டு அட்டவணையைப் படம் எடுங்கள், செயலி அதைப் படிக்கும். அல்லது உங்கள் வார்டு பயன்படுத்தும் அதே குறியீடுகளுடன் நாள்தோறும் உள்ளிடுங்கள். ஒரு மாதத்துக்குச் சுமார் ஒரு நிமிடம் ஆகும்.',
  'Scan: photo of the roster, check, save':
      'ஸ்கேன்: அட்டவணைப் படம், சரிபார், சேமி',
  'Type: tap each day and choose 7, 1, N, D, 24, DO or leave':
      'தட்டச்சு: ஒவ்வொரு நாளையும் தொட்டு 7, 1, N, D, 24, DO அல்லது விடுப்பைத் தேர்ந்தெடுங்கள்',
  '“Fill rota” fills a repeating pattern in one tap':
      '“சுழற்சியை நிரப்பு” ஒரே தொடுதலில் மீண்டும் வரும் முறையை நிரப்பும்',
  'Home → Quick Actions → Scan Image or Manual Input':
      'முகப்பு → விரைவுச் செயல்கள் → படத்தை ஸ்கேன் செய் அல்லது கைமுறை உள்ளீடு',
  'Scan': 'ஸ்கேன்',
  'Type': 'தட்டச்சு',
  'Step 2 · Once': 'படி 2 · ஒருமுறை',
  'Set your pay details': 'உங்கள் சம்பள விவரங்களை அமையுங்கள்',
  'Enter your basic salary, night allowance and monthly allowances such as COLA. Then check the Pay rules match your hospital. You do this once; change it when your salary changes.':
      'உங்கள் அடிப்படைச் சம்பளம், இரவுக் கொடுப்பனவு மற்றும் COLA போன்ற மாதாந்தக் கொடுப்பனவுகளை உள்ளிடுங்கள். பின்னர் சம்பள விதிகள் உங்கள் மருத்துவமனைக்குப் பொருந்துகிறதா எனச் சரிபாருங்கள். இதை ஒருமுறை செய்யுங்கள்; சம்பளம் மாறும்போது மாற்றுங்கள்.',
  'Basic salary, or pick your grade':
      'அடிப்படைச் சம்பளம், அல்லது உங்கள் தரத்தைத் தேர்ந்தெடுங்கள்',
  'Allowances and deductions (COLA, W&OP…)':
      'கொடுப்பனவுகள் மற்றும் கழிவுகள் (COLA, W&OP…)',
  'Pay rules: OT, holiday duty and leave days':
      'சம்பள விதிகள்: OT, விடுமுறைப் பணி மற்றும் விடுப்பு நாட்கள்',
  'Profile → Pay settings': 'சுயவிவரம் → சம்பள அமைப்புகள்',
  'Every duty · Daily': 'ஒவ்வொரு பணியும் · தினமும்',
  'Start and end each duty with one tap':
      'ஒவ்வொரு பணியையும் ஒரே தொடுதலில் தொடங்கி முடியுங்கள்',
  'When you arrive, tap Start duty. When you leave, tap End duty. The app records the time, splits main shift and OT, and shows what you earned.':
      'வந்ததும் “பணியைத் தொடங்கு” என்பதைத் தொடுங்கள். புறப்படும்போது “பணியை முடி” என்பதைத் தொடுங்கள். செயலி நேரத்தைப் பதிவுசெய்து, முதன்மைப் பணியையும் OT ஐயும் பிரித்து, நீங்கள் ஈட்டியதைக் காட்டும்.',
  'Start duty: one tap at the start of your shift':
      'பணியைத் தொடங்கு: பணி தொடக்கத்தில் ஒரே தொடுதல்',
  'On D and 24 duties OT starts by itself after the main hours, with a reminder':
      'D மற்றும் 24 பணிகளில் முதன்மை மணிநேரத்துக்குப் பின் OT தானாகத் தொடங்கி, நினைவூட்டல் வரும்',
  'End duty: see main hours, OT and pay for the duty':
      'பணியை முடி: முதன்மை மணிநேரம், OT மற்றும் கொடுப்பனவைப் பாருங்கள்',
  "Home → Today's Shift": 'முகப்பு → இன்றைய பணி',
  'When plans change': 'திட்டங்கள் மாறும்போது',
  'Leave, swaps and holidays': 'விடுப்பு, மாற்றங்கள் மற்றும் விடுமுறைகள்',
  'Tap any duty to change it. Your leave balance and salary update straight away.':
      'மாற்ற எந்தப் பணியையும் தொடுங்கள். உங்கள் விடுப்பு இருப்பும் சம்பளமும் உடனே புதுப்பிக்கப்படும்.',
  'Missed a duty? Mark Casual, Sick or No-pay leave in one tap':
      'பணியைத் தவறவிட்டீர்களா? தற்செயல், மருத்துவ அல்லது சம்பளமில்லா விடுப்பை ஒரே தொடுதலில் குறியுங்கள்',
  'Swapped with a colleague? Record who took it and the duty you took':
      'சக ஊழியருடன் மாற்றினீர்களா? யார் எடுத்தார் மற்றும் நீங்கள் எடுத்த பணியைப் பதிவு செய்யுங்கள்',
  'Worked a public holiday? Switch on Public holiday duty':
      'பொது விடுமுறையில் பணியாற்றினீர்களா? “பொது விடுமுறைப் பணி” ஐ இயக்குங்கள்',
  'After a night duty the next day shows as your sleep day':
      'இரவுப் பணிக்குப் பின் அடுத்த நாள் உங்கள் உறக்க நாளாகக் காட்டப்படும்',
  "Home → Today's Shift, or Roster → tap a day":
      'முகப்பு → இன்றைய பணி, அல்லது பணி அட்டவணை → ஒரு நாளைத் தொடுங்கள்',
  'Every month': 'ஒவ்வொரு மாதமும்',
  'Know your salary before payday':
      'சம்பள நாளுக்கு முன்பே உங்கள் சம்பளத்தை அறியுங்கள்',
  'The Salary tab works out your expected take-home pay from your roster, OT, allowances and leave, and shows a payslip preview to check against the real one.':
      'சம்பளத் தாவல் உங்கள் அட்டவணை, OT, கொடுப்பனவுகள் மற்றும் விடுப்பிலிருந்து எதிர்பார்க்கப்படும் நிகரச் சம்பளத்தைக் கணக்கிட்டு, உண்மையான சம்பளச் சீட்டுடன் ஒப்பிட முன்னோட்டம் காட்டும்.',
  'Projected take-home pay and a payslip preview':
      'கணிக்கப்பட்ட நிகரச் சம்பளம் மற்றும் சம்பளச் சீட்டு முன்னோட்டம்',
  'Leave used and remaining for the year':
      'ஆண்டுக்குப் பயன்படுத்திய மற்றும் மீதமுள்ள விடுப்பு',
  'Weekly hours and burnout warnings':
      'வாராந்த மணிநேரம் மற்றும் சோர்வு எச்சரிக்கைகள்',
  'Bottom bar → Salary Analytics and Roster':
      'கீழ்ப் பட்டி → சம்பள பகுப்பாய்வு மற்றும் பணி அட்டவணை',
  "You're ready!": 'நீங்கள் தயார்!',
  'Your whole routine, in four steps. The app does the counting.':
      'உங்கள் முழு வழக்கம், நான்கு படிகளில். கணக்குகளைச் செயலி செய்யும்.',
  'Once a month': 'மாதத்துக்கு ஒருமுறை',
  'Add your roster': 'உங்கள் அட்டவணையைச் சேருங்கள்',
  'Every duty': 'ஒவ்வொரு பணியும்',
  'Tap Start duty and End duty':
      '“பணியைத் தொடங்கு” மற்றும் “பணியை முடி” என்பதைத் தொடுங்கள்',
  'When it happens': 'நடக்கும்போது',
  'Record leave, swaps and holiday duty':
      'விடுப்பு, மாற்றங்கள் மற்றும் விடுமுறைப் பணியைப் பதிவு செய்யுங்கள்',
  'Any time': 'எப்போது வேண்டுமானாலும்',
  'Check your salary and leave': 'உங்கள் சம்பளத்தையும் விடுப்பையும் பாருங்கள்',
  'What you get: every OT hour and allowance counted, your leave always up to date, and your salary known before payday.':
      'உங்களுக்குக் கிடைப்பது: ஒவ்வொரு OT மணிநேரமும் கொடுப்பனவும் கணக்கிடப்படும், உங்கள் விடுப்பு எப்போதும் புதுப்பிக்கப்பட்டிருக்கும், சம்பள நாளுக்கு முன்பே சம்பளம் தெரியும்.',
  'Start now': 'இப்போதே தொடங்குங்கள்',
  'Scan my roster': 'என் அட்டவணையை ஸ்கேன் செய்',
  'Type my roster': 'என் அட்டவணையைத் தட்டச்சு செய்',
  'Set my pay': 'என் சம்பளத்தை அமை',
  'Go to my dashboard': 'என் முகப்புக்குச் செல்',
  'You can open this guide again from App Settings or the menu.':
      'இந்த வழிகாட்டியை செயலி அமைப்புகள் அல்லது பட்டியிலிருந்து மீண்டும் திறக்கலாம்.',
  'You can change the language any time in App Settings.':
      'செயலி அமைப்புகளில் எப்போது வேண்டுமானாலும் மொழியை மாற்றலாம்.',
  'Where: {path}': 'எங்கே: {path}',
  'Next': 'அடுத்து',
  'App guide': 'செயலி வழிகாட்டி',
  'How to use the app': 'செயலியைப் பயன்படுத்துவது எப்படி',
  'Scan roster': 'அட்டவணையை ஸ்கேன் செய்',

  // Notifications
  'A reminder before each part of the duty ends':
      'பணியின் ஒவ்வொரு பகுதியும் முடிவதற்கு முன் ஒரு நினைவூட்டல்',
  'Add your monthly deductions (W&OP, loans…) so your take-home pay is exact.':
      'உங்கள் நிகரச் சம்பளம் துல்லியமாக இருக்க மாதாந்தக் கழிவுகளை (W&OP, கடன்…) சேருங்கள்.',
  'Add your pay details': 'உங்கள் சம்பள விவரங்களைச் சேருங்கள்',
  'After your last duty: hours, OT and what you earned that day':
      'உங்கள் கடைசிப் பணிக்குப் பின்: அன்றைய மணிநேரம், OT மற்றும் ஈட்டியது',
  'Before the main shift and OT end':
      'முதன்மைப் பணியும் OT யும் முடிவதற்கு முன்',
  'Daily summary': 'தினசரிச் சுருக்கம்',
  'Did you start your duty?': 'உங்கள் பணியைத் தொடங்கினீர்களா?',
  'Duty reminders, your daily summary and messages will appear here.':
      'பணி நினைவூட்டல்கள், தினசரிச் சுருக்கம் மற்றும் செய்திகள் இங்கே தோன்றும்.',
  'Earlier': 'முன்பு',
  'Forgot to start': 'தொடங்க மறந்தால்',
  'If your salary or deductions are missing; at most once a week':
      'உங்கள் சம்பளம் அல்லது கழிவுகள் இல்லையெனில்; வாரத்துக்கு அதிகபட்சம் ஒருமுறை',
  'Main Shift Completed!': 'முதன்மைப் பணி முடிந்தது!',
  'Main shift ends in {lead}': 'முதன்மைப் பணி {lead} இல் முடியும்',
  'Mark all as read': 'அனைத்தையும் படித்ததாகக் குறி',
  'No notifications yet': 'இன்னும் அறிவிப்புகள் இல்லை',
  'Notifications ({n})': 'அறிவிப்புகள் ({n})',
  'OT ends in {lead}': 'OT {lead} இல் முடியும்',
  'OT starts automatically at {time}. No need to sign out.':
      'OT {time} இல் தானாகத் தொடங்கும். வெளியேறத் தேவையில்லை.',
  'Pay details reminder': 'சம்பள விவர நினைவூட்டல்',
  "Phone notifications are off. Reminders still appear here, but your phone won't alert you.":
      'தொலைபேசி அறிவிப்புகள் முடக்கப்பட்டுள்ளன. நினைவூட்டல்கள் இங்கே தோன்றும், ஆனால் தொலைபேசி உங்களை எச்சரிக்காது.',
  "Remind me if a duty has started and I haven't tapped Start duty":
      'பணி தொடங்கியும் நான் “பணியைத் தொடங்கு” என்பதைத் தொடவில்லையெனில் நினைவூட்டு',
  'Starts at {time}': '{time} இல் தொடங்கும்',
  'Starts at {time} · {hours} h OT planned':
      '{time} இல் தொடங்கும் · {hours} மணி OT திட்டமிடப்பட்டுள்ளது',
  'Switched to Overtime (OT) Mode. Keep up the great work! 🩺':
      'மேலதிக நேர (OT) முறைக்கு மாறியது. சிறப்பாகத் தொடருங்கள்! 🩺',
  "Today's summary": 'இன்றைய சுருக்கம்',
  'Turn on': 'இயக்கு',
  'Your OT ends at {time}. Tap End duty when you leave.':
      'உங்கள் OT {time} இல் முடியும். புறப்படும்போது “பணியை முடி” என்பதைத் தொடுங்கள்.',
  "Your basic salary isn't set yet, so your earnings are estimates. It takes a minute.":
      'உங்கள் அடிப்படைச் சம்பளம் இன்னும் அமைக்கப்படவில்லை, அதனால் வருமானம் மதிப்பீடுகள் மட்டுமே. ஒரு நிமிடம் போதும்.',
  'Your main shift ends at {time}. End duty, or stay on OT.':
      'உங்கள் முதன்மைப் பணி {time} இல் முடியும். பணியை முடியுங்கள், அல்லது OT தொடருங்கள்.',
  'Your {shift} started at {time}. Tap Start duty so your hours and OT are counted.':
      'உங்கள் {shift} {time} இல் தொடங்கியது. உங்கள் மணிநேரமும் OT யும் கணக்கிடப்பட “பணியைத் தொடங்கு” என்பதைத் தொடுங்கள்.',
  '{hours} h worked · {ot} h OT · {pay} extra earned (OT and allowances). This month so far: {month}.':
      '{hours} மணி பணி · {ot} மணி OT · கூடுதலாக {pay} ஈட்டப்பட்டது (OT மற்றும் கொடுப்பனவுகள்). இந்த மாதம் இதுவரை: {month}.',
  '{shift} in {lead}': '{shift} {lead} இல்',
};
