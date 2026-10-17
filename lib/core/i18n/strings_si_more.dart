/// Sinhala translations, part 2: roster, analytics, sign-up, pay rules, swaps and
/// date words. Keyed by the English text.
const sinhalaStringsMore = <String, String>{
  // Dates and times
  'Mon': 'සඳු',
  'Tue': 'අඟ',
  'Wed': 'බදා',
  'Thu': 'බ්‍රහස්',
  'Fri': 'සිකු',
  'Sat': 'සෙන',
  'Sun': 'ඉරි',
  'Jan': 'ජන',
  'Feb': 'පෙබ',
  'Mar': 'මාර්තු',
  'Apr': 'අප්‍රේල්',
  'May': 'මැයි',
  'Jun': 'ජූනි',
  'Jul': 'ජූලි',
  'Aug': 'අගෝ',
  'Sep': 'සැප්',
  'Oct': 'ඔක්',
  'Nov': 'නොවැ',
  'Dec': 'දෙසැ',
  '{n} min': 'විනාඩි {n}',
  '{n} h': 'පැය {n}',
  '{t} ago': '{t}කට පෙර',
  'in {t}': '{t}කින්',
  'Days': 'දින',
  'days taken': 'දින ගත්තා',

  // Duty steps
  'Check in': 'පැමිණීම සටහන් කරන්න',
  'Check-in done': 'පැමිණීම සටහන් විය',
  'Signed in at {time}': '{time}ට පැමිණියා',
  'Starts {when} · {time}': '{when} ආරම්භ වේ · {time}',
  'Shift started at {time}': 'මුරය {time}ට ආරම්භ විය',
  'Main shift done': 'ප්‍රධාන මුරය අවසන්',
  'Signed out at {time}': '{time}ට පිටවිය',
  'Main shift ending': 'ප්‍රධාන මුරය අවසන් වෙමින්',
  'Main shift ended': 'ප්‍රධාන මුරය අවසන් විය',
  'Ended {time} · sign out': '{time}ට අවසන් විය · පිටවන්න',
  'Ends at {time}': '{time}ට අවසන් වේ',
  'OT done': 'OT අවසන්',
  '{hours} hrs logged': 'පැය {hours}ක් සටහන් විය',
  'OT in progress': 'OT සිදුවෙමින්',
  'Started at {time}': '{time}ට ආරම්භ විය',
  'Started {time}': '{time}ට ආරම්භ විය',
  'OT starts automatically': 'OT ස්වයංක්‍රීයව ආරම්භ වේ',
  'at {time} · {hours} hrs, no sign-out needed':
      '{time}ට · පැය {hours}, පිටවීම අවශ්‍ය නැත',
  'OT shift starting': 'OT මුරය ආරම්භ වේ',
  'at {time} · {hours} hrs': '{time}ට · පැය {hours}',
  'OT (optional)': 'OT (අවශ්‍ය නම්)',
  'Switch to OT when you sign out': 'පිටවන විට OT වෙත මාරු වන්න',
  'OT starts after {hours} hrs': 'පැය {hours}කට පසු OT ආරම්භ වේ',
  "Today's Shift": 'අද මුරය',
  "This Month's\nPredicted Salary": 'මෙම මාසයේ\nඅපේක්ෂිත වැටුප',

  // Sleep day, swaps, holidays
  'Sleep day': 'නින්ද දිනය',
  'Rest after your night duty. No duty today.':
      'රාත්‍රී රාජකාරියෙන් පසු විවේක ගන්න. අද රාජකාරියක් නැත.',
  'Your night duty ends at 07:00 this morning. This duty starts straight after it, with no sleep.':
      'ඔබේ රාත්‍රී රාජකාරිය අද උදේ 07:00ට අවසන් වේ. මෙම රාජකාරිය නින්දක් නොමැතිව ඉන් පසුව ම ආරම්භ වේ.',
  'Swap with a colleague': 'සගයෙකු සමඟ මාරු කරන්න',
  "Colleague's name": 'සගයාගේ නම',
  'I take one of their duties': 'මම ඔවුන්ගේ රාජකාරියක් භාර ගනිමි',
  'Swap': 'මාරු කරන්න',
  'Swapped': 'මාරු කළා',
  'Duty swapped': 'රාජකාරිය මාරු කළා',
  'Duty swapped with {name}': '{name} සමඟ රාජකාරිය මාරු කළා',
  'Given to {name}': '{name}ට දුන්නා',
  'Given to {name} in a duty swap': 'රාජකාරි මාරුවකින් {name}ට දුන්නා',
  'Swapped to a colleague': 'සගයෙකුට මාරු කළා',
  'Public holiday duty': 'රජයේ නිවාඩු දින රාජකාරිය',
  'Marked as public holiday duty': 'රජයේ නිවාඩු දින රාජකාරිය ලෙස සලකුණු විය',
  'Public holiday removed': 'රජයේ නිවාඩු දිනය ඉවත් කළා',
  'Sunday duty is counted automatically':
      'ඉරිදා රාජකාරිය ස්වයංක්‍රීයව ගණන් කෙරේ',
  'Earns the holiday rate set in Pay rules':
      'වැටුප් නීතිවල සකසා ඇති නිවාඩු දින ගාස්තුව ලැබේ',

  // Pay rules
  'Pay rules': 'වැටුප් නීති',
  'Pay rules saved': 'වැටුප් නීති සුරැකිණි',
  'Save pay rules': 'වැටුප් නීති සුරකින්න',
  "Defaults follow common government practice. Hospitals differ, so check these with your hospital and change any that don't match.":
      'පෙරනිමි අගයන් සාමාන්‍ය රජයේ ක්‍රමය අනුගමනය කරයි. රෝහල් අනුව වෙනස් විය හැකි නිසා, ඔබේ රෝහල සමඟ පරීක්ෂා කර නොගැළපෙන ඒවා වෙනස් කරන්න.',
  'Employer': 'සේවා ස්ථානය',
  'Government': 'රජයේ',
  'Private': 'පෞද්ගලික',
  "Private hospitals usually pay a fixed OT hourly rate: set it under Pay settings. Remove COLA and W&OP there if they don't apply to you.":
      'පෞද්ගලික රෝහල් සාමාන්‍යයෙන් ස්ථාවර OT පැය ගාස්තුවක් ගෙවයි: එය වැටුප් සැකසුම් තුළ සකසන්න. COLA සහ W&OP ඔබට අදාළ නොවේ නම් එහි ඉවත් කරන්න.',
  'Salary grade': 'වැටුප් ශ්‍රේණිය',
  'Grade': 'ශ්‍රේණිය',
  'Salary step (increments)': 'වැටුප් පියවර (වර්ධක)',
  'Basic salary at this step: {amount}': 'මෙම පියවරේ මූලික වැටුප: {amount}',
  'Saving replaces your current basic of {amount}.':
      'සුරැකීමෙන් ඔබේ වත්මන් මූලික වැටුප {amount} ප්‍රතිස්ථාපනය වේ.',
  'How OT is counted': 'OT ගණන් කරන ආකාරය',
  'Per duty': 'රාජකාරියකට',
  'OT recorded on each duty (after the main shift, or the extra hours of a D / 24 duty).':
      'සෑම රාජකාරියකම සටහන් වූ OT (ප්‍රධාන මුරයෙන් පසු, හෝ D / 24 රාජකාරියක අමතර පැය).',
  'From monthly hours': 'මාසික පැය අනුව',
  'Every hour worked in the month beyond the required duty hours is OT.':
      'මාසය තුළ අවශ්‍ය රාජකාරි පැයට වඩා වැඩ කළ සෑම පැයක්ම OT වේ.',
  'Required hours a month': 'මාසයකට අවශ්‍ය පැය',
  'Hourly rate divisor': 'පැය ගාස්තු බෙදීම',
  'Basic salary ÷ this = basic hourly rate':
      'මූලික වැටුප ÷ මෙය = මූලික පැය ගාස්තුව',
  'Sunday & public holiday duty': 'ඉරිදා සහ රජයේ නිවාඩු දින රාජකාරිය',
  'Extra pay for each main-shift hour, as a multiple of the basic hourly rate.':
      'සෑම ප්‍රධාන මුර පැයකටම අමතර ගෙවීම, මූලික පැය ගාස්තුවේ ගුණාකාරයක් ලෙස.',
  'Off': 'අක්‍රිය',
  'Sundays count as holidays': 'ඉරිදා නිවාඩු දින ලෙස ගණන් කරන්න',
  'Mark public holidays on the duty itself (Public holiday duty).':
      'රජයේ නිවාඩු දින රාජකාරිය මත ම සලකුණු කරන්න (රජයේ නිවාඩු දින රාජකාරිය).',
  'Leave entitlements (days a year)': 'නිවාඩු හිමිකම් (වසරකට දින)',
  '0 = no fixed quota': '0 = ස්ථාවර සීමාවක් නැත',
  'Decrease': 'අඩු කරන්න',
  'Increase': 'වැඩි කරන්න',
  'Leave 0 to use basic ÷ {divisor} × multiplier':
      'මූලික ÷ {divisor} × ගුණකය භාවිතයට 0 ලෙස තබන්න',
  'Auto · {amount}': 'ස්වයං · {amount}',
  'Connected to {server}': '{server} වෙත සම්බන්ධයි',

  // Roster screens
  'Manual Roster': 'අතින් ලේඛනය',
  'How to add your roster': 'ඔබේ ලේඛනය එක් කරන ආකාරය',
  'Tap a day to set its shift': 'මුරය සැකසීමට දිනයක් තට්ටු කරන්න',
  'Fill rota': 'රොටා පුරවන්න',
  'Fill with rota': 'රොටාවෙන් පුරවන්න',
  'Fill': 'පුරවන්න',
  'Start on day': 'ආරම්භක දිනය',
  'No changes': 'වෙනස්කම් නැත',
  'Not set': 'සකසා නැත',
  'Double shift · edit from Duty details':
      'ද්විත්ව මුරය · රාජකාරි විස්තරවලින් සංස්කරණය',
  'Change shift': 'මුරය වෙනස් කරන්න',
  'Clear day': 'දිනය හිස් කරන්න',
  'Next month': 'ඊළඟ මාසය',
  'Previous month': 'පෙර මාසය',
  'Day duty, 12 h': 'දිවා රාජකාරිය, පැය 12',
  'Short duty, 8 h': 'කෙටි රාජකාරිය, පැය 8',
  'Absent': 'නොපැමිණි',
  'Type your duty roster day by day. It takes about a minute for a whole month.':
      'ඔබේ රාජකාරි ලේඛනය දිනෙන් දින ඇතුළත් කරන්න. මුළු මාසයකටම විනාඩියක් පමණ ගත වේ.',
  'Pick the month': 'මාසය තෝරන්න',
  'Use ‹ › at the top. You can go up to 3 months back or ahead.':
      'ඉහළ ‹ › භාවිත කරන්න. මාස 3ක් පසුපසට හෝ ඉදිරියට යා හැක.',
  'Set each day': 'සෑම දිනයක්ම සකසන්න',
  'Tap the code badge on the right of a day and choose its duty, leave or day off. Choose “Clear day” to remove it.':
      'දිනයක දකුණු පස කේත ලාංඡනය තට්ටු කර රාජකාරිය, නිවාඩුව හෝ නිවාඩු දිනය තෝරන්න. ඉවත් කිරීමට “දිනය හිස් කරන්න” තෝරන්න.',
  'Fill a whole month fast': 'මුළු මාසයම ඉක්මනින් පුරවන්න',
  '“Fill rota” fills empty days with 7 7 1 1 N N DO, starting on the day you pick. Days you already set are never overwritten.':
      '“රොටා පුරවන්න” ඔබ තෝරන දිනයේ සිට හිස් දින 7 7 1 1 N N DO ලෙස පුරවයි. ඔබ දැනටමත් සැකසූ දින කිසිවිටෙක වෙනස් නොවේ.',
  'Changed days get a purple dot. Tap “Save” at the bottom to keep them; leaving without saving discards them.':
      'වෙනස් කළ දිනවලට දම් පැහැති තිතක් ලැබේ. ඒවා තබා ගැනීමට පහළ “සුරකින්න” තට්ටු කරන්න; නොසුරැක ඉවත් වුවහොත් ඒවා අහිමි වේ.',
  'Locked days': 'අගුළු දැමූ දින',
  'A day with more than one entry (e.g. Morning + Evening) is locked here. Change it from Duty & Roster details instead.':
      'ඇතුළත් කිරීම් එකකට වඩා ඇති දිනයක් (උදා: උදෑසන + සවස) මෙහි අගුළු දමා ඇත. ඒ වෙනුවට රාජකාරි සහ ලේඛන විස්තරවලින් වෙනස් කරන්න.',
  'Duty codes': 'රාජකාරි කේත',
  'The same codes as your ward roster.': 'ඔබේ වාට්ටු ලේඛනයේ ඇති කේතම.',
  'D and 24 duties include their OT automatically (6 h + 6 h and 6 h + 18 h). Have a photo of the roster? Use Scan Roster instead and fix only what it misreads.':
      'D සහ 24 රාජකාරිවල OT ස්වයංක්‍රීයව ඇතුළත් වේ (පැය 6 + 6 සහ 6 + 18). ලේඛනයේ ඡායාරූපයක් තිබේද? ලේඛනය ස්කෑන් කරන්න භාවිත කර වැරදි ලෙස කියවූ දේ පමණක් නිවැරදි කරන්න.',
  'Got it': 'තේරුණා',
  'Scan Roster': 'ලේඛනය ස්කෑන් කරන්න',
  'Roster month': 'ලේඛන මාසය',
  'Take photo': 'ඡායාරූපයක් ගන්න',
  'From gallery': 'ගැලරියෙන්',
  'Paste roster text instead': 'ඒ වෙනුවට ලේඛන පෙළ අලවන්න',
  'Paste roster text': 'ලේඛන පෙළ අලවන්න',
  "Text from your phone's text scanner works too":
      'ඔබේ දුරකථනයේ පෙළ ස්කෑනරයෙන් ලැබෙන පෙළ ද ක්‍රියා කරයි',
  'Read': 'කියවන්න',
  'Your name as printed (optional)': 'මුද්‍රණය කර ඇති ඔබේ නම (අවශ්‍ය නම්)',
  'For ward rosters with one row per nurse, e.g. "K. PERERA"':
      'හෙදියකට එක් පේළියක් ඇති වාට්ටු ලේඛන සඳහා, උදා: "K. PERERA"',
  'For a clean read': 'පැහැදිලි කියවීමක් සඳහා',
  'Lay the roster flat in good light': 'ලේඛනය හොඳ ආලෝකයේ පැතලිව තබන්න',
  'Fill the frame and hold the phone straight':
      'රාමුව පුරවා දුරකථනය කෙළින් අල්ලා ගන්න',
  'Include the row of day numbers': 'දින අංක පේළිය ඇතුළත් කරන්න',
  'Reading your {month} roster…': 'ඔබේ {month} ලේඛනය කියවමින්…',
  'Review Roster': 'ලේඛනය සමාලෝචනය',
  'All clear': 'සියල්ල හරි',
  'Needs a look': 'බැලිය යුතුයි',
  'Tap a code to change it. Swipe a row away to drop it.':
      'වෙනස් කිරීමට කේතයක් තට්ටු කරන්න. ඉවත් කිරීමට පේළියක් ස්වයිප් කරන්න.',
  'Replace days I already entered':
      'මා දැනටමත් ඇතුළත් කළ දින ප්‍රතිස්ථාපනය කරන්න',
  'Set': 'සකසන්න',
  'Nothing could be read from this photo. Go back and try a clearer, well-lit shot.':
      'මෙම ඡායාරූපයෙන් කිසිවක් කියවිය නොහැකි විය. ආපසු ගොස් වඩා පැහැදිලි, හොඳ ආලෝකයක් ඇති ඡායාරූපයක් උත්සාහ කරන්න.',
  'Read as "{code}"': '"{code}" ලෙස කියවිණි',
  'Read as "{code}" · please check':
      '"{code}" ලෙස කියවිණි · කරුණාකර පරීක්ෂා කරන්න',

  // Analytics
  'Projected take-home': 'අපේක්ෂිත ශුද්ධ වැටුප',
  'Likely {low} – {high}': 'බොහෝ විට {low} – {high}',
  'Roster alone gives {amount}; the forecast adds your usual extra OT and absences.':
      'ලේඛනය පමණක් {amount} දෙයි; පුරෝකථනය ඔබේ සාමාන්‍ය අමතර OT සහ නොපැමිණීම් එක් කරයි.',
  'Earned so far': 'මෙතෙක් උපයාගත්',
  'Basic (so far)': 'මූලික (මෙතෙක්)',
  'Overtime': 'අතිකාලය',
  'Allowances': 'දීමනා',
  'OT this month': 'මෙම මාසයේ OT',
  'Rostered': 'ලේඛනයේ',
  'Likely extra': 'බොහෝ විට අමතර',
  'Likely {low}–{high} hrs': 'බොහෝ විට පැය {low}–{high}',
  'Your usual month: {hours} hrs of OT': 'ඔබේ සාමාන්‍ය මාසය: OT පැය {hours}',
  'OT by weekday': 'සතියේ දින අනුව OT',
  'OT habit:': 'OT පුරුද්ද:',
  'Smart forecast': 'ස්මාර්ට් පුරෝකථනය',
  'Your plan shows a roster-based estimate. Upgrade to add your usual extra OT, absences and a confidence score.':
      'ඔබේ සැලැස්ම ලේඛනය මත පදනම් වූ ඇස්තමේන්තුවක් පෙන්වයි. ඔබේ සාමාන්‍ය අමතර OT, නොපැමිණීම් සහ විශ්වාස ලකුණක් එක් කිරීමට උසස් කරන්න.',
  'Payslip preview': 'වැටුප් පත්‍රිකා පෙරදසුන',
  'Gross': 'දළ',
  'Deductions': 'අඩු කිරීම්',
  'Fixed deductions': 'ස්ථාවර අඩු කිරීම්',
  'No-pay deductions': 'වැටුප් රහිත අඩු කිරීම්',
  'Net (LKR)': 'ශුද්ධ (රු.)',
  'How is this calculated?': 'මෙය ගණනය කරන්නේ කෙසේද?',
  'Confidence factors': 'විශ්වාස සාධක',
  'Month already worked': 'දැනටමත් වැඩ කළ මාසය',
  'Roster filled in': 'ලේඛනය පුරවා ඇත',
  'OT consistency': 'OT ස්ථාවරත්වය',
  'History available': 'පවතින ඉතිහාසය',
  'Workload & wellbeing': 'වැඩ බර සහ යහපැවැත්ම',
  'Workload & burnout insights': 'වැඩ බර සහ වෙහෙස පිළිබඳ තොරතුරු',
  'Shift mix, weekly hours and burnout risk are part of a higher plan.':
      'මුර මිශ්‍රණය, සතිපතා පැය සහ වෙහෙස අවදානම ඉහළ සැලැස්මක කොටසකි.',
  'Burnout risk': 'වෙහෙස අවදානම',
  'Your recent workload looks balanced. Keep it up!':
      'ඔබේ මෑත වැඩ බර සමතුලිතයි. දිගටම කරගෙන යන්න!',
  'Shift mix · last 3 months': 'මුර මිශ්‍රණය · පසුගිය මාස 3',
  'Off-day OT': 'නිවාඩු දින OT',
  'Avg. weekly': 'සතිපතා සාමාන්‍යය',
  'OT share': 'OT කොටස',
  'OT rising': 'OT වැඩි වෙමින්',
  'OT falling': 'OT අඩු වෙමින්',
  'OT steady': 'OT ස්ථාවරයි',
  'These figures use a typical nursing salary. Add yours for exact predictions.':
      'මෙම සංඛ්‍යා සාමාන්‍ය හෙද වැටුපක් භාවිත කරයි. නිවැරදි පුරෝකථන සඳහා ඔබේ වැටුප එක් කරන්න.',
  'Week of {day}': '{day} සතිය',
  'Main {hours}h': 'ප්‍රධාන පැය {hours}',
  'This month so far: {ot} OT · {night} night allowance':
      'මෙම මාසයේ මෙතෙක්: OT {ot} · රාත්‍රී දීමනාව {night}',

  // Onboarding
  'Make your salary exact': 'ඔබේ වැටුප නිවැරදි කරන්න',
  'To calculate your exact salary & OT predictions, please enter your Base Salary & Hourly OT Rate.':
      'ඔබේ නිවැරදි වැටුප සහ OT පුරෝකථන ගණනය කිරීමට, කරුණාකර ඔබේ මූලික වැටුප සහ OT පැය ගාස්තුව ඇතුළත් කරන්න.',
  'Base salary (LKR / month)': 'මූලික වැටුප (රු. / මාසය)',
  'OT rate (LKR / hour)': 'OT ගාස්තුව (රු. / පැය)',
  'Optional. Leave empty to use basic ÷ 240 × 1.5':
      'අවශ්‍ය නම් පමණි. මූලික ÷ 240 × 1.5 භාවිතයට හිස්ව තබන්න',
  'Save & predict': 'සුරකා පුරෝකථනය කරන්න',
  'Skip for now (Use Default Estimate)': 'දැනට මඟ හරින්න (පෙරනිමි ඇස්තමේන්තුව)',
  'Salary saved. Predictions are now exact':
      'වැටුප සුරැකිණි. පුරෝකථන දැන් නිවැරදියි',
  'Using a typical salary estimate for now':
      'දැනට සාමාන්‍ය වැටුප් ඇස්තමේන්තුවක් භාවිත වේ',
  'Estimate · add your salary': 'ඇස්තමේන්තුව · ඔබේ වැටුප එක් කරන්න',
  'Enter your basic salary': 'ඔබේ මූලික වැටුප ඇතුළත් කරන්න',
  'Enter an amount in LKR': 'රුපියල්වලින් මුදලක් ඇතුළත් කරන්න',
  'That looks too high': 'එය ඉතා ඉහළ ලෙස පෙනේ',
  'Which ward?': 'කුමන වාට්ටුවද?',
  'Select your primary hospital': 'ඔබේ ප්‍රධාන රෝහල තෝරන්න',
  'Search hospitals': 'රෝහල් සොයන්න',
  'Use "{name}"': '"{name}" භාවිත කරන්න',
  'Ward number (optional)': 'වාට්ටු අංකය (අවශ්‍ය නම්)',
  'Optional. Helps match your roster rows.':
      'අවශ්‍ය නම් පමණි. ඔබේ ලේඛන පේළි ගැළපීමට උපකාරී වේ.',
  'We use it to label your roster. You can change it any time.':
      'ඔබේ ලේඛනය නම් කිරීමට එය භාවිත වේ. ඕනෑම වේලාවක වෙනස් කළ හැක.',
  'Save & continue': 'සුරකා ඉදිරියට',
  'Skip': 'මඟ හරින්න',
  'Never miss a shift': 'කිසිදු මුරයක් මඟ නොහරින්න',
  'Turn on reminders': 'සිහිකැඳවීම් සක්‍රිය කරන්න',
  'Not now': 'දැන් නොවේ',
  'Notifications are blocked. You can turn them on later in Profile.':
      'දැනුම්දීම් අවහිරයි. පසුව පැතිකඩ තුළ සක්‍රිය කළ හැක.',

  // Sign up and validation
  'Create your account': 'ඔබේ ගිණුම සාදන්න',
  'Takes 10 seconds. Pay and ward details can wait until you need them.':
      'තත්පර 10ක් ගත වේ. වැටුප් සහ වාට්ටු විස්තර අවශ්‍ය වන තුරු රැඳී සිටිය හැක.',
  'Your name': 'ඔබේ නම',
  'Create account': 'ගිණුම සාදන්න',
  "No salary or ward details needed now: we'll ask only when a feature needs them.":
      'දැන් වැටුප් හෝ වාට්ටු විස්තර අවශ්‍ය නැත: අංගයකට අවශ්‍ය වූ විට පමණක් අසමු.',
  'Required': 'අවශ්‍යයි',
  'Enter a valid email': 'වලංගු ඊමේල් ලිපිනයක් ඇතුළත් කරන්න',
  'At least 8 characters': 'අවම අක්ෂර 8ක්',
  'At most 72 characters': 'උපරිම අක්ෂර 72ක්',
  'Use letters and numbers': 'අකුරු සහ අංක භාවිත කරන්න',
  'Enter an email or a mobile like 077 123 4567':
      '077 123 4567 වැනි ජංගම අංකයක් හෝ ඊමේල් ලිපිනයක් ඇතුළත් කරන්න',
  'Enter your email or mobile number': 'ඔබේ ඊමේල් හෝ ජංගම අංකය ඇතුළත් කරන්න',
  'Enter your email': 'ඔබේ ඊමේල් ඇතුළත් කරන්න',

  // Google sign-in
  'Use email or mobile': 'ඊමේල් හෝ ජංගම අංකය භාවිත කරන්න',
  "Google sign-in didn't work. Please try again or use your email/mobile.":
      'Google පිවිසුම ක්‍රියා කළේ නැත. නැවත උත්සාහ කරන්න හෝ ඔබේ ඊමේල්/ජංගම අංකය භාවිත කරන්න.',
  'You used Google last time': 'ඔබ පසුගිය වතාවේ Google භාවිත කළා',
  'Fastest: one tap, no password': 'වේගවත්ම: එක් තට්ටුවක්, මුරපදයක් නැත',

  // App guide
  'Welcome': 'ආයුබෝවන්',
  'What is Nurse Companion?': 'Nurse Companion යනු කුමක්ද?',
  'A personal assistant for nurses in Sri Lanka. It keeps your duty roster, overtime, leave and salary together in one place, and does the counting for you.':
      'ශ්‍රී ලංකාවේ හෙදියන් සඳහා පුද්ගලික සහායකයෙක්. ඔබේ රාජකාරි ලේඛනය, අතිකාලය, නිවාඩු සහ වැටුප එක තැනක තබාගෙන, ගණනය කිරීම් ඔබ වෙනුවෙන් කරයි.',
  'Your duty roster for the whole month': 'මුළු මාසයේම ඔබේ රාජකාරි ලේඛනය',
  'Every OT hour, counted correctly': 'සෑම OT පැයක්ම නිවැරදිව ගණනය වේ',
  'Leave taken and leave remaining': 'ගත් නිවාඩු සහ ඉතිරි නිවාඩු',
  'Your salary, before payday': 'වැටුප් දිනට පෙර ඔබේ වැටුප',
  'Why use it': 'භාවිත කළ යුත්තේ ඇයි',
  'Less paperwork. No missed pay.': 'කඩදාසි වැඩ අඩුයි. ගෙවීම් මඟ නොහැරේ.',
  'Most nurses track duties in a notebook and work out OT by hand. Mistakes mean lost money. Nurse Companion records everything as you work.':
      'බොහෝ හෙදියන් රාජකාරි සටහන් පොතක ලියා OT අතින් ගණනය කරයි. වැරදි නිසා මුදල් අහිමි වේ. Nurse Companion ඔබ වැඩ කරන අතරතුර සියල්ල සටහන් කරයි.',
  'No more notebooks or calculators':
      'සටහන් පොත් හෝ ගණක යන්ත්‍ර තවදුරටත් අවශ්‍ය නැත',
  'OT on D and 24 duties is counted automatically':
      'D සහ 24 රාජකාරිවල OT ස්වයංක්‍රීයව ගණනය වේ',
  'Night allowance and holiday duty are not forgotten':
      'රාත්‍රී දීමනාව සහ නිවාඩු දින රාජකාරිය අමතක නොවේ',
  'Check your payslip against your own record':
      'ඔබේ වැටුප් පත්‍රිකාව ඔබේම සටහන සමඟ සසඳන්න',
  'Step 1 · Once a month': 'පියවර 1 · මාසයකට වරක්',
  'Add your duty roster': 'ඔබේ රාජකාරි ලේඛනය එක් කරන්න',
  'Take a photo of your ward roster and the app reads it, or type it day by day with the same codes your ward uses. A month takes about a minute.':
      'ඔබේ වාට්ටු ලේඛනයේ ඡායාරූපයක් ගන්න, යෙදුම එය කියවයි. නැතහොත් ඔබේ වාට්ටුව භාවිත කරන කේතම යොදා දිනෙන් දින ඇතුළත් කරන්න. මාසයකට විනාඩියක් පමණ ගත වේ.',
  'Scan: photo of the roster, check, save':
      'ස්කෑන්: ලේඛනයේ ඡායාරූපය, පරීක්ෂා කිරීම, සුරැකීම',
  'Type: tap each day and choose 7, 1, N, D, 24, DO or leave':
      'ටයිප්: සෑම දිනයක්ම තට්ටු කර 7, 1, N, D, 24, DO හෝ නිවාඩු තෝරන්න',
  '“Fill rota” fills a repeating pattern in one tap':
      '“රොටා පුරවන්න” එක් තට්ටුවකින් පුනරාවර්තන රටාවක් පුරවයි',
  'Home → Quick Actions → Scan Image or Manual Input':
      'මුල් පිටුව → ඉක්මන් ක්‍රියා → රූපය ස්කෑන් කරන්න හෝ අතින් ඇතුළත් කිරීම',
  'Scan': 'ස්කෑන්',
  'Type': 'ටයිප්',
  'Step 2 · Once': 'පියවර 2 · එක් වරක්',
  'Set your pay details': 'ඔබේ වැටුප් විස්තර සකසන්න',
  'Enter your basic salary, night allowance and monthly allowances such as COLA. Then check the Pay rules match your hospital. You do this once; change it when your salary changes.':
      'ඔබේ මූලික වැටුප, රාත්‍රී දීමනාව සහ COLA වැනි මාසික දීමනා ඇතුළත් කරන්න. ඉන්පසු වැටුප් නීති ඔබේ රෝහලට ගැළපේදැයි පරීක්ෂා කරන්න. මෙය එක් වරක් කරන්න; වැටුප වෙනස් වූ විට යාවත්කාලීන කරන්න.',
  'Basic salary, or pick your grade': 'මූලික වැටුප, හෝ ඔබේ ශ්‍රේණිය තෝරන්න',
  'Allowances and deductions (COLA, W&OP…)':
      'දීමනා සහ අඩු කිරීම් (COLA, W&OP…)',
  'Pay rules: OT, holiday duty and leave days':
      'වැටුප් නීති: OT, නිවාඩු දින රාජකාරිය සහ නිවාඩු දින',
  'Profile → Pay settings': 'පැතිකඩ → වැටුප් සැකසුම්',
  'Every duty · Daily': 'සෑම රාජකාරියක්ම · දිනපතා',
  'Start and end each duty with one tap':
      'සෑම රාජකාරියක්ම එක් තට්ටුවකින් අරඹා අවසන් කරන්න',
  'When you arrive, tap Start duty. When you leave, tap End duty. The app records the time, splits main shift and OT, and shows what you earned.':
      'පැමිණි විට “රාජකාරිය අරඹන්න” තට්ටු කරන්න. පිටවන විට “රාජකාරිය අවසන් කරන්න” තට්ටු කරන්න. යෙදුම වේලාව සටහන් කර, ප්‍රධාන මුරය සහ OT වෙන් කර, ඔබ උපයාගත් දේ පෙන්වයි.',
  'Start duty: one tap at the start of your shift':
      'රාජකාරිය අරඹන්න: මුරය ආරම්භයේ එක් තට්ටුවක්',
  'On D and 24 duties OT starts by itself after the main hours, with a reminder':
      'D සහ 24 රාජකාරිවල ප්‍රධාන පැයෙන් පසු OT ස්වයංක්‍රීයව ආරම්භ වී, සිහිකැඳවීමක් ලැබේ',
  'End duty: see main hours, OT and pay for the duty':
      'රාජකාරිය අවසන් කරන්න: ප්‍රධාන පැය, OT සහ ගෙවීම බලන්න',
  "Home → Today's Shift": 'මුල් පිටුව → අද මුරය',
  'When plans change': 'සැලසුම් වෙනස් වන විට',
  'Leave, swaps and holidays': 'නිවාඩු, මාරු සහ නිවාඩු දින',
  'Tap any duty to change it. Your leave balance and salary update straight away.':
      'වෙනස් කිරීමට ඕනෑම රාජකාරියක් තට්ටු කරන්න. ඔබේ නිවාඩු ශේෂය සහ වැටුප වහාම යාවත්කාලීන වේ.',
  'Missed a duty? Mark Casual, Sick or No-pay leave in one tap':
      'රාජකාරියක් මඟ හැරුණාද? අනියම්, අසනීප හෝ වැටුප් රහිත නිවාඩු එක් තට්ටුවකින් සටහන් කරන්න',
  'Swapped with a colleague? Record who took it and the duty you took':
      'සගයෙකු සමඟ මාරු කළාද? එය ගත්තේ කවුද සහ ඔබ ගත් රාජකාරිය සටහන් කරන්න',
  'Worked a public holiday? Switch on Public holiday duty':
      'රජයේ නිවාඩු දිනයක වැඩ කළාද? “රජයේ නිවාඩු දින රාජකාරිය” සක්‍රිය කරන්න',
  'After a night duty the next day shows as your sleep day':
      'රාත්‍රී රාජකාරියකින් පසු ඊළඟ දිනය ඔබේ නින්ද දිනය ලෙස පෙන්වයි',
  "Home → Today's Shift, or Roster → tap a day":
      'මුල් පිටුව → අද මුරය, හෝ රාජකාරි ලේඛනය → දිනයක් තට්ටු කරන්න',
  'Every month': 'සෑම මාසයකම',
  'Know your salary before payday': 'වැටුප් දිනට පෙර ඔබේ වැටුප දැනගන්න',
  'The Salary tab works out your expected take-home pay from your roster, OT, allowances and leave, and shows a payslip preview to check against the real one.':
      'වැටුප් ටැබය ඔබේ ලේඛනය, OT, දීමනා සහ නිවාඩු අනුව අපේක්ෂිත ශුද්ධ වැටුප ගණනය කර, සැබෑ වැටුප් පත්‍රිකාව සමඟ සසඳා බැලීමට පෙරදසුනක් පෙන්වයි.',
  'Projected take-home pay and a payslip preview':
      'අපේක්ෂිත ශුද්ධ වැටුප සහ වැටුප් පත්‍රිකා පෙරදසුන',
  'Leave used and remaining for the year': 'වසර සඳහා භාවිත කළ සහ ඉතිරි නිවාඩු',
  'Weekly hours and burnout warnings': 'සතිපතා පැය සහ වෙහෙස අනතුරු ඇඟවීම්',
  'Bottom bar → Salary Analytics and Roster':
      'පහළ තීරුව → වැටුප් විශ්ලේෂණය සහ රාජකාරි ලේඛනය',
  "You're ready!": 'ඔබ සූදානම්!',
  'Your whole routine, in four steps. The app does the counting.':
      'ඔබේ සම්පූර්ණ දින චර්යාව, පියවර හතරකින්. ගණනය කිරීම් යෙදුම කරයි.',
  'Once a month': 'මාසයකට වරක්',
  'Add your roster': 'ඔබේ ලේඛනය එක් කරන්න',
  'Every duty': 'සෑම රාජකාරියක්ම',
  'Tap Start duty and End duty':
      '“රාජකාරිය අරඹන්න” සහ “රාජකාරිය අවසන් කරන්න” තට්ටු කරන්න',
  'When it happens': 'සිදු වූ විට',
  'Record leave, swaps and holiday duty':
      'නිවාඩු, මාරු සහ නිවාඩු දින රාජකාරිය සටහන් කරන්න',
  'Any time': 'ඕනෑම වේලාවක',
  'Check your salary and leave': 'ඔබේ වැටුප සහ නිවාඩු බලන්න',
  'What you get: every OT hour and allowance counted, your leave always up to date, and your salary known before payday.':
      'ඔබට ලැබෙන දේ: සෑම OT පැයක්ම සහ දීමනාවක්ම ගණනය වේ, ඔබේ නිවාඩු සැමවිටම යාවත්කාලීනයි, වැටුප් දිනට පෙර ඔබේ වැටුප දැනගත හැක.',
  'Start now': 'දැන් අරඹන්න',
  'Scan my roster': 'මගේ ලේඛනය ස්කෑන් කරන්න',
  'Type my roster': 'මගේ ලේඛනය ටයිප් කරන්න',
  'Set my pay': 'මගේ වැටුප සකසන්න',
  'Go to my dashboard': 'මගේ මුල් පිටුවට යන්න',
  'You can open this guide again from App Settings or the menu.':
      'මෙම මාර්ගෝපදේශය යෙදුම් සැකසුම් හෝ මෙනුවෙන් නැවත විවෘත කළ හැක.',
  'You can change the language any time in App Settings.':
      'යෙදුම් සැකසුම් තුළ ඕනෑම වේලාවක භාෂාව වෙනස් කළ හැක.',
  'Where: {path}': 'කොහේද: {path}',
  'Next': 'ඊළඟ',
  'App guide': 'යෙදුම් මාර්ගෝපදේශය',
  'How to use the app': 'යෙදුම භාවිත කරන ආකාරය',
  'Scan roster': 'ලේඛනය ස්කෑන් කරන්න',

  // Notifications
  'A reminder before each part of the duty ends':
      'රාජකාරියේ සෑම කොටසක්ම අවසන් වීමට පෙර සිහිකැඳවීමක්',
  'Add your monthly deductions (W&OP, loans…) so your take-home pay is exact.':
      'ඔබේ ශුද්ධ වැටුප නිවැරදි වීමට මාසික අඩු කිරීම් (W&OP, ණය…) එක් කරන්න.',
  'Add your pay details': 'ඔබේ වැටුප් විස්තර එක් කරන්න',
  'After your last duty: hours, OT and what you earned that day':
      'ඔබේ අවසන් රාජකාරියෙන් පසු: එදින පැය, OT සහ උපයාගත් මුදල',
  'Before the main shift and OT end': 'ප්‍රධාන මුරය සහ OT අවසන් වීමට පෙර',
  'Daily summary': 'දෛනික සාරාංශය',
  'Did you start your duty?': 'ඔබ රාජකාරිය ආරම්භ කළාද?',
  'Duty reminders, your daily summary and messages will appear here.':
      'රාජකාරි සිහිකැඳවීම්, දෛනික සාරාංශය සහ පණිවිඩ මෙහි පෙන්වයි.',
  'Earlier': 'කලින්',
  'Forgot to start': 'ආරම්භ කිරීමට අමතක වූ විට',
  'If your salary or deductions are missing; at most once a week':
      'ඔබේ වැටුප හෝ අඩු කිරීම් නොමැති නම්; සතියකට වරක් පමණි',
  'Main Shift Completed!': 'ප්‍රධාන මුරය අවසන්!',
  'Main shift ends in {lead}': 'ප්‍රධාන මුරය {lead}කින් අවසන් වේ',
  'Mark all as read': 'සියල්ල කියවූ ලෙස සලකුණු කරන්න',
  'No notifications yet': 'තවම දැනුම්දීම් නැත',
  'Notifications ({n})': 'දැනුම්දීම් ({n})',
  'OT ends in {lead}': 'OT {lead}කින් අවසන් වේ',
  'OT starts automatically at {time}. No need to sign out.':
      'OT {time}ට ස්වයංක්‍රීයව ආරම්භ වේ. පිටවීම අවශ්‍ය නැත.',
  'Pay details reminder': 'වැටුප් විස්තර සිහිකැඳවීම',
  "Phone notifications are off. Reminders still appear here, but your phone won't alert you.":
      'දුරකථන දැනුම්දීම් අක්‍රියයි. සිහිකැඳවීම් මෙහි පෙන්වන නමුත් ඔබේ දුරකථනය ඔබට දන්වන්නේ නැත.',
  "Remind me if a duty has started and I haven't tapped Start duty":
      'රාජකාරිය ආරම්භ වී මා “රාජකාරිය අරඹන්න” තට්ටු නොකළේ නම් මතක් කරන්න',
  'Starts at {time}': '{time}ට ආරම්භ වේ',
  'Starts at {time} · {hours} h OT planned':
      '{time}ට ආරම්භ වේ · OT පැය {hours}ක් සැලසුම් කර ඇත',
  'Switched to Overtime (OT) Mode. Keep up the great work! 🩺':
      'අතිකාල (OT) ප්‍රකාරයට මාරු විය. දිගටම හොඳින් කරගෙන යන්න! 🩺',
  "Today's summary": 'අද සාරාංශය',
  'Turn on': 'සක්‍රිය කරන්න',
  'Your OT ends at {time}. Tap End duty when you leave.':
      'ඔබේ OT {time}ට අවසන් වේ. පිටවන විට “රාජකාරිය අවසන් කරන්න” තට්ටු කරන්න.',
  "Your basic salary isn't set yet, so your earnings are estimates. It takes a minute.":
      'ඔබේ මූලික වැටුප තවම සකසා නැති නිසා ඉපැයීම් ඇස්තමේන්තු පමණි. විනාඩියක් පමණ ගත වේ.',
  'Your main shift ends at {time}. End duty, or stay on OT.':
      'ඔබේ ප්‍රධාන මුරය {time}ට අවසන් වේ. රාජකාරිය අවසන් කරන්න, නැතහොත් OT දිගටම කරන්න.',
  'Your {shift} started at {time}. Tap Start duty so your hours and OT are counted.':
      'ඔබේ {shift} {time}ට ආරම්භ විය. ඔබේ පැය සහ OT ගණන් වීමට “රාජකාරිය අරඹන්න” තට්ටු කරන්න.',
  '{hours} h worked · {ot} h OT · {pay} extra earned (OT and allowances). This month so far: {month}.':
      'පැය {hours} වැඩ කළා · OT පැය {ot} · අමතරව {pay} උපයා ගත්තා (OT සහ දීමනා). මෙම මාසයේ මෙතෙක්: {month}.',
  '{shift} in {lead}': '{shift} {lead}කින්',
};
