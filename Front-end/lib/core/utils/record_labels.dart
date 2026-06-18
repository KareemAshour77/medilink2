// Localized labels for records / prescriptions / appointments.
// Centralised so every screen shows the same Arabic/English text.

import '../../l10n/app_localizations.dart';

/// Backend record type (lab_test|imaging|prescription|diagnosis) → localized.
String recordTypeLabelL10n(AppLocalizations l, String? apiType) {
  switch (apiType) {
    case 'lab_test':     return l.recordTypeLab;
    case 'imaging':      return l.recordTypeImaging;
    case 'prescription': return l.recordTypePrescription;
    case 'diagnosis':    return l.recordTypeDiagnosis;
    default:             return apiType ?? '';
  }
}

/// Prescription status (taking_now|effective|not_effective) → localized.
String rxStatusLabelL10n(AppLocalizations l, String? status) {
  switch (status) {
    case 'taking_now':    return l.rxTakingNow;
    case 'effective':     return l.rxEffective;
    case 'not_effective': return l.rxNotEffective;
    default:              return status ?? '';
  }
}

/// Appointment status (pending|confirmed|rejected|ended) → localized.
String apptStatusLabelL10n(AppLocalizations l, String? status) {
  switch (status) {
    case 'confirmed': return l.apptConfirmed;
    case 'rejected':  return l.apptRejected;
    case 'ended':     return l.apptEnded;
    default:          return l.apptPending;
  }
}

/// Appointment type (Follow-Up|Check-Up|Consultation) → localized.
String apptTypeLabelL10n(AppLocalizations l, String? type) {
  switch (type) {
    case 'Follow-Up':    return l.apptFollowUp;
    case 'Check-Up':     return l.apptCheckUp;
    case 'Consultation': return l.apptConsultation;
    default:             return type ?? '';
  }
}

/// The three prescription statuses as (apiId, localized label) pairs.
List<(String, String)> rxStatusOptionsL10n(AppLocalizations l) => [
      ('taking_now', l.rxTakingNow),
      ('effective', l.rxEffective),
      ('not_effective', l.rxNotEffective),
    ];
