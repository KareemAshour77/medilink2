// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'MediLink';

  @override
  String get tagline => 'Tu enlace con los médicos';

  @override
  String get splashTagline => 'Tu enlace con los médicos';

  @override
  String get next => 'Siguiente';

  @override
  String get getStarted => 'Comenzar';

  @override
  String get onboarding1Title => 'Chatbot de IA';

  @override
  String get onboarding1Desc => 'El chatbot de IA analiza tus registros y guía tu atención';

  @override
  String get onboarding2Title => 'Cerca de ti';

  @override
  String get onboarding2Desc => 'Encuentra los médicos, farmacias y laboratorios más cercanos';

  @override
  String get onboarding3Title => 'Recordatorio';

  @override
  String get onboarding3Desc => 'Notificaciones inteligentes para medicamentos, citas y análisis';

  @override
  String get onboarding4Title => 'Historial médico';

  @override
  String get onboarding4Desc => 'Almacena todos tus documentos médicos digitalmente: análisis, informes, recetas';

  @override
  String get welcomeCompanion => 'Tu compañero médico diario';

  @override
  String get welcomeDesc => 'Encuentra médicos, compra medicamentos y guarda todo tu historial médico en un solo lugar.';

  @override
  String get signUp => 'Registrarse';

  @override
  String get logIn => 'Iniciar sesión';

  @override
  String get orContinueWith => 'o continuar con';

  @override
  String get alreadyHaveAccount => '¿Ya tienes una cuenta? ';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get helloThere => '¡Hola!';

  @override
  String get loginToContinue => 'Inicia sesión para continuar';

  @override
  String get emailOrPhone => 'Correo ';

  @override
  String get enterEmailOrPhone => 'Ingresa correo ';

  @override
  String get password => 'Contraseña';

  @override
  String get forgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get login => 'Entrar';

  @override
  String get orSignInWith => 'o iniciar sesión con';

  @override
  String get dontHaveAccount => '¿No tienes una cuenta? ';

  @override
  String get signUpTitle => 'Registrarse';

  @override
  String get completeProfile => 'Completa tu perfil';

  @override
  String get onlyYouCanSee => 'Solo tú puedes ver tu información personal.';

  @override
  String get fullName => 'Nombre completo';

  @override
  String get fullNameHint => 'Nombre completo';

  @override
  String get gender => 'Género';

  @override
  String get male => 'Masculino';

  @override
  String get female => 'Femenino';

  @override
  String get registerAs => 'Registrarse como';

  @override
  String get patient => 'Paciente';

  @override
  String get doctor => 'Médico';

  @override
  String get pharmacy => 'Farmacia';

  @override
  String get scan => 'Centro de radiología';

  @override
  String get nationalId => 'DNI';

  @override
  String get nationalIdHint => 'DNI';

  @override
  String get email => 'Correo electrónico';

  @override
  String get emailHint => 'Dirección de correo';

  @override
  String get createPassword => 'Crear contraseña';

  @override
  String get newPasswordHint => 'Nueva contraseña';

  @override
  String get confirmPassword => 'Confirmar contraseña';

  @override
  String get confirmPasswordHint => 'Confirmar contraseña';

  @override
  String get phoneNumber => 'Número de teléfono';

  @override
  String get phoneVerificationDesc => 'Necesitamos tu número para verificación.';

  @override
  String get phoneHint => 'Número de teléfono';

  @override
  String get fullNameReq => '*El nombre completo es obligatorio';

  @override
  String get nationalIdReq => '*El DNI es obligatorio';

  @override
  String get nationalIdMiss => '*El DNI debe tener 14 dígitos';

  @override
  String get emailReq => '*El correo es obligatorio';

  @override
  String get emailMissAt => '*El correo debe contener @';

  @override
  String get emailMissDot => '*El correo debe contener .com';

  @override
  String get newPasswordReq => 'La contraseña es obligatoria';

  @override
  String get newPasswordUpp => 'La contraseña debe contener una letra mayúscula';

  @override
  String get newPasswordNum => 'La contraseña debe contener un número';

  @override
  String get newPasswordSym => 'La contraseña debe contener un símbolo';

  @override
  String get confirmPasswordMatch => 'Las contraseñas no coinciden';

  @override
  String hiUser(Object name) {
    return 'Hola, $name ';
  }

  @override
  String get howAreYou => '¿Cómo estás hoy?';

  @override
  String get searchHint => 'Buscar médico, farmacia...';

  @override
  String get doctors => 'Médicos';

  @override
  String get pharmacy2 => 'Farmacia';

  @override
  String get labs => 'Laboratorios';

  @override
  String get scans => 'Centros de radiología';

  @override
  String get seeAll => 'Ver todo';

  @override
  String get aiAssistantTitle => 'Asistente de salud IA';

  @override
  String get aiAssistantDesc => 'Pregunta cualquier cosa sobre tu\nsalud, registros o médicos';

  @override
  String get chatNow => 'Chatear ahora  →';

  @override
  String get upcomingSchedule => 'Próximas citas';

  @override
  String get topDoctors => 'Médicos más cercanos';

  @override
  String get topPharmacy => 'Farmacias más cercanas';

  @override
  String get topLabs => 'Laboratorios más cercanos';

  @override
  String get topScans => 'Centros de radiología más cercanos';

  @override
  String get take => 'Tomar';

  @override
  String get reviews => 'reseñas';

  @override
  String get reminders => 'Recordatorios';

  @override
  String get todaySchedule => 'Horario de hoy';

  @override
  String takenToday(Object taken, Object total) {
    return '$taken de $total tomados hoy';
  }

  @override
  String get newReminder => 'Nuevo recordatorio';

  @override
  String get editReminder => 'Editar recordatorio';

  @override
  String get addReminder => 'Agregar recordatorio';

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get docicon => 'Médico 🩺';

  @override
  String get type => 'Tipo';

  @override
  String get medicine => '💊 Medicamento';

  @override
  String get nameMedi => 'Nombre del medicamento';

  @override
  String get form => 'Forma';

  @override
  String get dosePerIntake => 'Dosis por toma';

  @override
  String get takeIt => 'Tomar';

  @override
  String get beforeMeal => '🍽️  Antes de comer';

  @override
  String get afterMeal => '🍽️  Después de comer';

  @override
  String get withFood => '🥗  Con comida';

  @override
  String get anytime => '⏱️  En cualquier momento';

  @override
  String get priority => 'Prioridad';

  @override
  String get high => '🔴  Alta';

  @override
  String get normal => '🟡  Normal';

  @override
  String get low => '🟢  Baja';

  @override
  String get pickAColor => 'Elige un color';

  @override
  String get color => 'Color';

  @override
  String get tapToChangeColor => 'Toca para cambiar el color';

  @override
  String get reminderTime => 'Hora del recordatorio';

  @override
  String get repeatOn => 'Repetir el';

  @override
  String get duration => 'Duración';

  @override
  String get noEndDate => 'Sin fecha de fin';

  @override
  String get holdToEdit => 'Mantén para editar  •  Desliza a la izquierda para eliminar';

  @override
  String get ateAlready => 'Ya comí';

  @override
  String get noRemindersYet => 'Aún no hay recordatorios';

  @override
  String get tapToAddOne => 'Toca + para agregar uno';

  @override
  String get doneTick => 'Listo ✓';

  @override
  String get medicalRecords => 'Historial médico';

  @override
  String documentsStored(Object count) {
    return '$count documentos almacenados';
  }

  @override
  String get menu => 'Menú';

  @override
  String get nearBy => 'Cerca de ti';

  @override
  String get refreshLocation => 'Actualizar ubicación';

  @override
  String get clinicLocation => 'Ubicación de la clínica';

  @override
  String get myProfile => 'Mi perfil';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get helpSupport => 'Ayuda y soporte';

  @override
  String get aiChatBot => 'Chatbot de IA';

  @override
  String get askAnything => 'Pregunta cualquier cosa sobre tu salud';

  @override
  String get open => 'Abrir';

  @override
  String get logOut => 'Cerrar sesión';

  @override
  String get home => 'Inicio';

  @override
  String get reminder => 'Recordatorio';

  @override
  String get records => 'Registros';

  @override
  String get medibot => 'MediBot';

  @override
  String get online => 'En línea';

  @override
  String get typingHint => 'Escribe un mensaje...';

  @override
  String get medibotGreeting => '¡Hola! Soy MediBot 👋\n¿Cómo puedo ayudarte hoy?';

  @override
  String get medibotTyping => 'MediBot está escribiendo...';

  @override
  String get quickReply1 => 'Ver mis registros';

  @override
  String get quickReply2 => 'Reservar cita';

  @override
  String get quickReply3 => 'Horario de medicamentos';

  @override
  String get quickReply4 => 'Farmacia cercana';

  @override
  String get mon => 'Lun';

  @override
  String get tue => 'Mar';

  @override
  String get wed => 'Mié';

  @override
  String get thu => 'Jue';

  @override
  String get fri => 'Vie';

  @override
  String get sat => 'Sáb';

  @override
  String get sun => 'Dom';

  @override
  String get tablets => 'Comprimidos';

  @override
  String get capsules => 'Cápsulas';

  @override
  String get powders => 'Polvos';

  @override
  String get lozenges => 'Pastillas';

  @override
  String get syrups => 'Jarabes';

  @override
  String get dropsEye => 'Gotas oculares';

  @override
  String get dropsEar => 'Gotas óticas';

  @override
  String get dropsNasal => 'Gotas nasales';

  @override
  String get injections => 'Inyecciones';

  @override
  String get creamsOintmentsGel => 'Cremas & Ungüentos & Gel';

  @override
  String get inhalers => 'Inhaladores';

  @override
  String get suppositories => 'Supositorios';

  @override
  String get sublingualTablets => 'Comprimidos sublinguales';

  @override
  String get themes => 'Apariencia';

  @override
  String get chooseTheme => 'Elige tu apariencia preferida';

  @override
  String get lightTheme => 'Claro';

  @override
  String get darkTheme => 'Oscuro';

  @override
  String get systemDefault => 'Predeterminado del sistema';

  @override
  String get followsDeviceSetting => 'Sigue la configuración de tu dispositivo';

  @override
  String get language => 'Idioma';

  @override
  String get chooseLanguage => 'Elige tu idioma preferido';

  @override
  String get labTest => 'Análisis de laboratorio';

  @override
  String get imaging => 'Imágenes médicas';

  @override
  String get prescriptions => 'Recetas';

  @override
  String get diagnosisTab => 'Diagnóstico';

  @override
  String get allRecords => 'Todos los registros';

  @override
  String get stableStatus => 'Estable';

  @override
  String get critical => 'Crítico';

  @override
  String get pending => 'Pendiente';

  @override
  String get bloodTestResults => 'Resultados de análisis de sangre';

  @override
  String get drAhmedHassanLab => 'Dr. Ahmed Hassan — Lab El Cairo';

  @override
  String get bloodTestDiagnosis => 'Hemograma normal con leve deficiencia de hierro';

  @override
  String get recheckNote => 'Revisión en 3 meses. El paciente responde bien a los cambios de dieta.';

  @override
  String get ironDeficiency => 'Deficiencia de hierro';

  @override
  String get xRayChest => 'Radiografía de tórax';

  @override
  String get radiologyCenterMaadi => 'Centro de Radiología — Maadi';

  @override
  String get clearLungsNote => 'Pulmones limpios, sin anomalías detectadas.';

  @override
  String get chestClearNote => 'Tórax limpio. Tos probablemente viral. Se recomienda reposo y líquidos.';

  @override
  String get viralCough => 'Tos viral';

  @override
  String get drSaraClinic => 'Dra. Sara Mahmoud — Clínica';

  @override
  String get viralFluNote => 'Gripe viral. Debería resolverse en 5-7 días con reposo y líquidos.';

  @override
  String get flu => 'Gripe';

  @override
  String get cardiologyReport => 'Informe de cardiología';

  @override
  String get drOmarClinic => 'Dr. Omar Khalil — Clínica del Corazón';

  @override
  String get arrhythmiaNote => 'Arritmia leve detectada. Requiere seguimiento.';

  @override
  String get holterNote => 'Monitor Holter programado por 24 horas. Evitar ejercicio intenso hasta recibir alta.';

  @override
  String get arrhythmia => 'Arritmia';

  @override
  String get mRIBrainScan => 'Resonancia magnética cerebral';

  @override
  String get scanCenterHel => 'Centro de Imágenes — Heliopolis';

  @override
  String get migraineScanNote => 'Sin anomalías estructurales. Se observaron cambios relacionados con migraña.';

  @override
  String get mriDoctorNote => 'La RM confirma patrón de migraña. Sin tumores ni lesiones. Se recomienda examen anual.';

  @override
  String get migraine => 'Migraña';

  @override
  String get diabetesCheckup => 'Control de diabetes';

  @override
  String get drLaylaCenter => 'Dra. Layla Nour — Centro de Diabetes';

  @override
  String get diabetesDiagnosis => 'HbA1c elevada al 8,2 %. Se requiere manejo de diabetes.';

  @override
  String get diabetesDoctorNote => 'HbA1c debe bajar de 7 en los próximos 3 meses. Derivación a nutricionista realizada.';

  @override
  String get diabetes => 'Diabetes';

  @override
  String get fluDiagnosis => 'Diagnóstico de gripe';

  @override
  String get drAhmedClinic => 'Dr. Ahmed Hassan — Clínica 3';

  @override
  String get fluDiagnosisText => 'Influenza estacional tipo A';

  @override
  String get fluDoctorNote => 'Se aconseja al paciente quedarse en casa. Vacuna antigripal recomendada para la próxima temporada.';

  @override
  String get verification => 'Verificación';

  @override
  String get phoneVerification => 'Verificación telefónica';

  @override
  String get codeSentMessage => 'Enviamos un código de 4 dígitos a su número de teléfono.';

  @override
  String get didntReceiveCode => '¿No recibiste el código? ';

  @override
  String get resend => 'Reenviar código';

  @override
  String get verify => 'Verificar';

  @override
  String get titleIsRequired => 'El título es obligatorio';

  @override
  String get doctorFacilityIsRequired => 'El médico / centro es obligatorio';

  @override
  String get diagnosisIsRequired => 'El diagnóstico es obligatorio';

  @override
  String get selectAttachment => 'Seleccionar adjunto';

  @override
  String get addNewRecord => 'Agregar nuevo registro';

  @override
  String get recordType => 'Tipo de registro';

  @override
  String get recordTitle => 'Título del registro';

  @override
  String get egBloodTest => 'ej. Resultados de análisis de sangre';

  @override
  String get doctorFacility => 'Médico / Centro';

  @override
  String get egDoctorFacility => 'ej. Dr. Ahmed Hassan — Lab El Cairo';

  @override
  String get date => 'Fecha';

  @override
  String get status => 'Estado';

  @override
  String get stable => 'Estable';

  @override
  String get diagnosisDescription => 'Diagnóstico / Descripción';

  @override
  String get diagnosisHint => 'Describa el diagnóstico o los hallazgos…';

  @override
  String get doctorNotes => 'Notas del médico (opcional)';

  @override
  String get doctorNotesHint => 'Notas adicionales del médico…';

  @override
  String get attachments => 'Adjuntos';

  @override
  String get addFile => 'Agregar archivo';

  @override
  String get noAttachmentsYet => 'Sin adjuntos aún';

  @override
  String get saveRecord => 'Guardar registro';

  @override
  String get jan => 'Ene';

  @override
  String get feb => 'Feb';

  @override
  String get mar => 'Mar';

  @override
  String get apr => 'Abr';

  @override
  String get may => 'May';

  @override
  String get jun => 'Jun';

  @override
  String get jul => 'Jul';

  @override
  String get aug => 'Ago';

  @override
  String get sep => 'Sep';

  @override
  String get oct => 'Oct';

  @override
  String get nov => 'Nov';

  @override
  String get dec => 'Dic';

  @override
  String get prescription => 'Receta';

  @override
  String get diagnosis => 'Diagnóstico';

  @override
  String get drYoussef => 'Dr. Youssef Mohammed';

  @override
  String get gynecologist => 'Ginecología';

  @override
  String get yrsExp14 => '14 años exp.';

  @override
  String get drJana => 'Dra. Jana Wael';

  @override
  String get cardiology => 'Cardiología';

  @override
  String get yrsExp17 => '17 años exp.';

  @override
  String get drAmr => 'Dr. Amr Adel';

  @override
  String get orthopedics => 'Ortopedia';

  @override
  String get yrsExp19 => '19 años exp.';

  @override
  String get drMaya => 'Dra. Maya Tamer';

  @override
  String get pediatrics => 'Pediatría';

  @override
  String get yrsExp21 => '21 años exp.';

  @override
  String get drKareem => 'Dr. Kareem Ashour';

  @override
  String get generalPractitioner => 'Medicina general';

  @override
  String get yrsExp15 => '15 años exp.';

  @override
  String get drAya => 'Dra. Aya Bassem';

  @override
  String get internalMedicine => 'Medicina interna';

  @override
  String get yrsExp10 => '10 años exp.';

  @override
  String get drEhab => 'Dr. Ehab Hesham';

  @override
  String get pediatrician => 'Pediatra';

  @override
  String get yrsExp12 => '12 años exp.';

  @override
  String get drMohamed => 'Dr. Mohamed Hany';

  @override
  String get oncologist => 'Oncología';

  @override
  String get yrsExp9 => '9 años exp.';

  @override
  String get drSeif => 'Dr. Seif Mohamed';

  @override
  String get pulmonology => 'Neumología';

  @override
  String get yrsExp8 => '8 años exp.';

  @override
  String get drAhmed => 'Dr. Ahmed Samy';

  @override
  String get cardiologist => 'Cardiólogo';

  @override
  String get yrsExp20 => '20 años exp.';

  @override
  String get drSara => 'Dra. Sara Hassan';

  @override
  String get dermatologist => 'Dermatología';

  @override
  String get yrsExp7 => '7 años exp.';

  @override
  String get drOmar => 'Dr. Omar Farouk';

  @override
  String get neurologist => 'Neurología';

  @override
  String get yrsExp18 => '18 años exp.';

  @override
  String get drMona => 'Dra. Mona Ali';

  @override
  String get neurosurgery => 'Neurocirugía';

  @override
  String get yrsExp22 => '22 años exp.';

  @override
  String get book => 'Reservar';

  @override
  String get alNahda => 'Farmacia Al Nahdi';

  @override
  String get kmAwayZeroThree => '0,3 km';

  @override
  String get time1 => '8AM - 12AM';

  @override
  String get dawaa => 'Farmacia Dawaa';

  @override
  String get kmAwayZeroSeven => '0,7 km';

  @override
  String get time2 => '24 horas';

  @override
  String get seif => 'Farmacia Seif';

  @override
  String get kmAwayOneOne => '1,1 km';

  @override
  String get time3 => '9AM - 11PM';

  @override
  String get cairo => 'Farmacia Cairo';

  @override
  String get kmAwayOneEight => '1,8 km';

  @override
  String get time4 => '8AM - 10PM';

  @override
  String get elEzaby => 'Farmacia El Ezaby';

  @override
  String get kmAwayTwoTwo => '2,2 km';

  @override
  String get time5 => '24 horas';

  @override
  String get alphaMedical => 'Lab Médico Alpha';

  @override
  String get kmAwayZeroFive => '0,5 km';

  @override
  String get time6 => '7AM - 9PM';

  @override
  String get nileDiagnostics => 'Nilo Diagnósticos';

  @override
  String get kmAwayOneZero => '1,0 km';

  @override
  String get time7 => '8AM - 8PM';

  @override
  String get cairoCenter => 'Centro Lab Cairo';

  @override
  String get kmAwayOneFour => '1,4 km';

  @override
  String get time8 => '7AM - 10PM';

  @override
  String get elite => 'Lab Elite';

  @override
  String get kmAwayTwoZero => '2,0 km';

  @override
  String get time9 => '8AM - 6PM';

  @override
  String get radiologyPlus => 'Radiología Plus';

  @override
  String get kmAwayZeroSix => '0,6 km';

  @override
  String get time10 => '8AM - 10PM';

  @override
  String get mriScanCenter => 'Centro MRI y Escáner';

  @override
  String get kmAwayOneTwoo => '1,2 km';

  @override
  String get time11 => '9AM - 9PM';

  @override
  String get cairoRadiology => 'Radiología Cairo';

  @override
  String get kmAwayOneSix => '1,6 km';

  @override
  String get time12 => '8AM - 8PM';

  @override
  String get advancedImaging => 'Imágenes Avanzadas';

  @override
  String get kmAwayTwoFive => '2,5 km';

  @override
  String get time13 => '7AM - 7PM';

  @override
  String start(Object date) {
    return 'Start: $date';
  }

  @override
  String get recordTypeLab => 'Lab Test';

  @override
  String get recordTypeImaging => 'Imaging';

  @override
  String get recordTypePrescription => 'Prescription';

  @override
  String get recordTypeDiagnosis => 'Diagnosis';

  @override
  String get rxTakingNow => 'Taking now';

  @override
  String get rxEffective => 'Effective';

  @override
  String get rxNotEffective => 'Not effective';

  @override
  String get apptPending => 'Pending';

  @override
  String get apptConfirmed => 'Confirmed';

  @override
  String get apptRejected => 'Rejected';

  @override
  String get apptEnded => 'Ended';

  @override
  String get apptFollowUp => 'Follow-Up';

  @override
  String get apptCheckUp => 'Check-Up';

  @override
  String get apptConsultation => 'Consultation';

  @override
  String get viewRecords => 'View Records';

  @override
  String get btnChatNow => 'Chat Now';

  @override
  String get createPrescription => 'Create Prescription';

  @override
  String get approve => 'Approve';

  @override
  String get reject => 'Reject';

  @override
  String get updateStatus => 'Update Status';

  @override
  String get addRecord => 'Add Record';

  @override
  String get addLabel => 'Add';

  @override
  String get continueLabel => 'Continue';

  @override
  String get retry => 'Retry';

  @override
  String get loadingDots => 'Loading…';

  @override
  String get recordTypeLabel => 'Record Type';

  @override
  String get notesDescriptionOptional => 'Notes / Description (optional)';

  @override
  String get doctorNotesOptional => 'Doctor Notes (optional)';

  @override
  String get medications => 'Medications';

  @override
  String get drugName => 'Drug name';

  @override
  String get dosageHint => 'Dosage (e.g. 500mg)';

  @override
  String get frequencyHint => 'Frequency (e.g. 2x/day)';

  @override
  String get medicationStatus => 'Medication Status';

  @override
  String get tapToUpdateStatus => 'Tap to update how this medication is working for you.';

  @override
  String get addMedicationFirst => 'Add at least one medication.';

  @override
  String get recordSaved => 'Record saved';

  @override
  String get recordDetails => 'Record Details';

  @override
  String get noRecordsForPatient => 'No records for this patient yet.';

  @override
  String get noRecordsFound => 'No records found';

  @override
  String get forPatient => 'For';

  @override
  String get recordsAccess => 'Records access';

  @override
  String get accessRequested => 'Access requested';

  @override
  String get accessRequestSent => 'Access request sent';

  @override
  String get waitingPatientApproval => 'They have 15 minutes to approve. Tap View again once approved.';

  @override
  String get accessGranted => 'Access granted';

  @override
  String get requestRejected => 'Request rejected';

  @override
  String get accessExpired => 'This access request has expired';

  @override
  String get wantsToViewRecords => 'Wants to view your medical records.';

  @override
  String get noPendingAccess => 'No pending requests. When a doctor asks to view your medical records, the request appears here.';

  @override
  String get expiresInLabel => 'expires in';

  @override
  String get minutesShort => 'min';

  @override
  String get ok => 'OK';

  @override
  String get schedule => 'Schedule';

  @override
  String get pendingApprovals => 'pending approvals';

  @override
  String get filterAll => 'All';

  @override
  String get filterActive => 'Active';

  @override
  String get filterToday => 'Today';

  @override
  String get noAppointmentsYet => 'No appointments yet.';

  @override
  String get myAppointments => 'My Appointments';

  @override
  String get myPatients => 'My Patients';

  @override
  String get patientsUnderCare => 'under care';

  @override
  String get searchPatients => 'Search by name or condition…';

  @override
  String get noPatientsYet => 'No patients yet. Patients appear here after you approve their appointment.';

  @override
  String get availability => 'Availability';

  @override
  String get workingDays => 'Working days';

  @override
  String get workingHours => 'Working hours';

  @override
  String get slotDuration => 'Slot duration';

  @override
  String get dailyBreak => 'Daily break';

  @override
  String get saveAvailability => 'Save availability';

  @override
  String get availabilitySaved => 'Availability saved';

  @override
  String get startLabel => 'Start';

  @override
  String get endLabel => 'End';

  @override
  String get breakStart => 'Break start';

  @override
  String get breakEnd => 'Break end';

  @override
  String get bookAppointment => 'Book Appointment';

  @override
  String get selectAppointmentType => 'Select appointment type';

  @override
  String get chooseTime => 'Choose a time';

  @override
  String get requestAppointment => 'Request Appointment';

  @override
  String get noSlotsAvailable => 'No available slots on this day.';

  @override
  String get doctorNoAvailability => 'This doctor has not set their availability yet. Please check back later.';

  @override
  String get requestSentTo => 'Request sent to';
}
