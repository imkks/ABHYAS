class SafetyProfile {
  final bool pregnancy;
  final bool hypertension;
  final bool heartCondition;
  final bool epilepsy;
  final bool glaucoma;
  final bool hernia;
  final bool recentSurgery;
  final bool menstruation;
  final bool emptyStomachConfirmed;

  SafetyProfile({
    this.pregnancy = false,
    this.hypertension = false,
    this.heartCondition = false,
    this.epilepsy = false,
    this.glaucoma = false,
    this.hernia = false,
    this.recentSurgery = false,
    this.menstruation = false,
    this.emptyStomachConfirmed = false,
  });
}

class SafetyRulesEngine {
  /// SR-01, SR-02, SR-03, SR-04 checks
  static bool isPracticeAllowed(String practice, SafetyProfile profile, bool teacherCleared) {
    if (practice == 'kapalbhati' || practice == 'bhastrika' ||
        practice == 'antar_kumbhaka' || practice == 'bahya_kumbhaka' || practice == 'uddiyana_kriya' || practice == 'maha_bandha' ||
        practice == 'jalandhara' || practice == 'mula' || practice == 'bandhas') {

      if (profile.pregnancy) {
        return teacherCleared;
      }

      if (profile.hypertension || profile.heartCondition || profile.epilepsy || profile.glaucoma || profile.hernia || profile.recentSurgery) {
        return teacherCleared;
      }
    }

    if (profile.menstruation) {
       if (practice == 'kapalbhati' || practice == 'uddiyana_kriya' || practice == 'maha_bandha') {
           return false; // Suggested off during menstruation
       }
    }

    if (practice == 'uddiyana_kriya' || practice == 'maha_bandha') {
      if (!profile.emptyStomachConfirmed) {
        return false;
      }
    }

    return true;
  }
}
