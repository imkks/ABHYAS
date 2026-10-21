import 'package:flutter/material.dart';
import '../../core/audio_service.dart';
import '../../core/theme.dart';
import '../../data/user_repository.dart';
import '../../engine/safety/safety_rules_engine.dart';
import '../practice/practice_player_screen.dart';
import '../dhyan/yoga_nidra_screen.dart';

class RitualsScreen extends StatefulWidget {
  const RitualsScreen({super.key});

  @override
  State<RitualsScreen> createState() => _RitualsScreenState();
}

class _RitualsScreenState extends State<RitualsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AudioService _audioService = AudioService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _launchPractice(BuildContext context, String title, String practiceId) async {
    final profile = await UserRepository().loadProfile() ?? SafetyProfile();
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PracticePlayerScreen(
          safetyProfile: profile,
          practiceName: title,
          practiceId: practiceId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AbhyasTheme.darkBg,
      appBar: AppBar(
        title: const Text('Vidyapeeth (Learn & Explore)'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AbhyasTheme.saffron,
          labelColor: AbhyasTheme.saffron,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Pranayama'),
            Tab(text: 'Dhyan'),
            Tab(text: 'Mudras & Bandhas'),
            Tab(text: 'Vedic Rituals'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPranayamaTab(),
          _buildDhyanTab(),
          _buildMudrasBandhasTab(),
          _buildRitualsTab(),
        ],
      ),
    );
  }

  // TAB 1: PRANAYAMA ENCYCLOPEDIA
  Widget _buildPranayamaTab() {
    final List<Map<String, dynamic>> pranayamas = [
      {
        'id': 'nadi_shodhana',
        'title': 'Nadi Shodhana (Anulom Vilom)',
        'sanskrit': 'नाडी शोधन',
        'tag': 'Harmonizing',
        'color': AbhyasTheme.leaf,
        'summary': 'Alternate nostril breathing to purify Ida and Pingala nadis and balance brain hemispheres.',
        'benefits': 'Calms the nervous system, reduces stress, prepares the mind for deep meditation, balances autonomic nervous system.',
        'technique': 'Sit comfortably. Close right nostril with thumb, inhale through left for 4s. Close left with ring finger, exhale right for 4s. Inhale right 4s, exhale left 4s.',
        'caution': 'Practice gently without force. Keep shoulders and facial muscles relaxed.',
      },
      {
        'id': 'kapalbhati',
        'title': 'Kapalbhati Pranayama',
        'sanskrit': 'कपालभाति',
        'tag': 'Vitalizing Cleansing',
        'color': AbhyasTheme.saffron,
        'summary': 'Frontal brain cleansing kriya through active rhythmic abdominal exhalations and passive inhalations.',
        'benefits': 'Cleanses respiratory channels, invigorates brain cells, stimulates digestive fire (Jatharagni), dispels mental lethargy.',
        'technique': 'Take a gentle breath in. Contract the abdominal muscles sharply to expel breath through both nostrils. Allow inhalation to occur automatically. 60 strokes/min.',
        'caution': 'Contraindicated in pregnancy, uncontrolled hypertension, hernia, recent abdominal surgery, and during menstruation.',
      },
      {
        'id': 'bhramari',
        'title': 'Bhramari (Humming Bee Breath)',
        'sanskrit': 'भ्रामरी',
        'tag': 'Soothing / Vagal Toning',
        'color': Colors.indigoAccent,
        'summary': 'Produces a steady humming bee vibration on exhalation that stimulates nitric oxide release and tones the vagus nerve.',
        'benefits': 'Immediately lowers heart rate, relieves insomnia and anger, calms agitation, induces alpha brainwave state.',
        'technique': 'Close eyes and ears with thumbs/fingers (Shanmukhi mudra). Inhale deeply through nose. Exhale slowly while producing a smooth, melodious humming "Mmm" sound.',
        'caution': 'Safe for all practitioners. Stop if throat feels dry or irritated.',
      },
      {
        'id': 'ujjayi',
        'title': 'Ujjayi (Victorious / Ocean Breath)',
        'sanskrit': 'उज्जायी',
        'tag': 'Focus & Heat',
        'color': AbhyasTheme.sky,
        'summary': 'Breathing with gentle glottic constriction in the throat, creating an ocean-like whisper.',
        'benefits': 'Enhances internal warmth, improves concentration, regulates blood pressure, bridges outer sensory withdrawal (Pratyahara).',
        'technique': 'Slightly contract the epiglottis in the back of the throat. Inhale and exhale smoothly through both nostrils, creating a soft rushing sound like ocean waves.',
        'caution': 'Do not tighten the neck excessively. Keep breath smooth and unforced.',
      },
      {
        'id': 'sheetali',
        'title': 'Sheetali & Sheetkari',
        'sanskrit': 'शीतली',
        'tag': 'Cooling Lunar',
        'color': Colors.cyan,
        'summary': 'Inhaling through a curled tongue or clenched teeth to cool core temperature and quench thirst.',
        'benefits': 'Reduces body heat (Pitta), quenches thirst, soothes hunger, induces tranquility of mind.',
        'technique': 'Roll tongue into a tube (or smile with teeth touching for Sheetkari). Inhale slowly through tongue. Close mouth and exhale through both nostrils.',
        'caution': 'Avoid during severe cold weather, bronchitis, or low blood pressure.',
      },
      {
        'id': 'bhastrika',
        'title': 'Bhastrika (Bellows Breath)',
        'sanskrit': 'भस्त्रिका',
        'tag': 'Dynamic Energy',
        'color': Colors.deepOrange,
        'summary': 'Rapid, forceful inhalation and exhalation like blacksmith bellows, generating vital prana shakti.',
        'benefits': 'Awakens dormant kundalini energy, burns toxins, dramatically elevates oxygenation and mental clarity.',
        'technique': 'Inhale and exhale forcefully and rhythmically through the nose, expanding and contracting the chest and abdomen equally. Followed by a deep retention.',
        'caution': 'Contraindicated in heart conditions, high blood pressure, vertigo, and hernia.',
      },
      {
        'id': 'surya_bhedana',
        'title': 'Surya Bhedana',
        'sanskrit': 'सूर्यभेदन',
        'tag': 'Solar Activation',
        'color': Colors.amber,
        'summary': 'Piercing the sun channel by exclusively inhaling through the right nostril (Pingala) and exhaling left.',
        'benefits': 'Increases digestive vitality, destroys worms/infections, dispels sluggishness and lethargy.',
        'technique': 'Inhale slowly through right nostril only. Hold momentarily if comfortable. Exhale slowly through left nostril.',
        'caution': 'Avoid if suffering from fever, high blood pressure, or hyperacidity.',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pranayamas.length,
      itemBuilder: (context, index) {
        final item = pranayamas[index];
        final Color tagColor = item['color'] as Color;

        return Card(
          color: AbhyasTheme.darkSurface,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AbhyasTheme.line),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item['title'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: tagColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: tagColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        item['tag'] as String,
                        style: TextStyle(color: tagColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                Text(
                  item['sanskrit'] as String,
                  style: TextStyle(color: AbhyasTheme.saffron.withValues(alpha: 0.8), fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  item['summary'] as String,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: AbhyasTheme.line),
                const SizedBox(height: 10),
                Text('• Benefits: ${item['benefits']}', style: const TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 12)),
                const SizedBox(height: 4),
                Text('• Technique: ${item['technique']}', style: const TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 12)),
                const SizedBox(height: 4),
                Text('• Caution: ${item['caution']}', style: TextStyle(color: Colors.orange.shade300, fontSize: 11)),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AbhyasTheme.saffron,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.play_circle_fill, size: 16, color: Colors.black),
                    label: const Text('Practice This Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    onPressed: () => _launchPractice(context, item['title'] as String, item['id'] as String),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // TAB 2: DHYAN (MEDITATION)
  Widget _buildDhyanTab() {
    final List<Map<String, dynamic>> dhyanItems = [
      {
        'title': 'Breath Awareness (Prana Dharana)',
        'sub': 'Foundational Mindfulness',
        'desc': 'Cultivate the position of the witness (Sakshi Bhava). Observe the cool sensation of incoming breath and warm outgoing breath at the nostrils without altering rhythm.',
        'icon': Icons.self_improvement,
        'color': AbhyasTheme.leaf,
        'route': 'breath_awareness',
      },
      {
        'title': 'Yoga Nidra (Psychic Sleep)',
        'sub': 'Deep Conscious Rest & Sleep Induction',
        'desc': 'Systematic rotation of consciousness through the body parts, breath awareness, evoking pairs of opposites (heaviness/lightness), and visual archetypes for profound restorative sleep.',
        'icon': Icons.bedtime,
        'color': Colors.indigoAccent,
        'route': 'yoga_nidra',
      },
      {
        'title': 'Antar Mouna (Inner Silence)',
        'sub': 'Pratyahara & Thought Witnessing',
        'desc': 'Stage-by-stage practice: 1) Awareness of external sounds, 2) Awareness of the spontaneous thought process, 3) Conscious creation and disposal of thoughts, 4) Pure awareness free of thoughts.',
        'icon': Icons.graphic_eq,
        'color': Colors.deepOrange,
        'route': 'antar_mouna',
      },
      {
        'title': 'Trataka (Gazing Meditation)',
        'sub': 'Dharana & Third Eye Activation',
        'desc': 'Steadily gazing at an unblinking focal point (ghee lamp flame or black dot) until tears flow, then closing eyes to contemplate the internal after-image in Chidakasha.',
        'icon': Icons.visibility,
        'color': Colors.purpleAccent,
        'route': 'trataka',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dhyanItems.length,
      itemBuilder: (context, index) {
        final item = dhyanItems[index];
        final Color color = item['color'] as Color;

        return Card(
          color: AbhyasTheme.darkSurface,
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AbhyasTheme.line),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.15),
                      child: Icon(item['icon'] as IconData, color: color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(item['sub'] as String, style: TextStyle(color: color, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item['desc'] as String,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AbhyasTheme.darkSurfaceAlt,
                      foregroundColor: AbhyasTheme.saffron,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      if (item['route'] == 'yoga_nidra') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const YogaNidraScreen(durationMinutes: 20)),
                        );
                      } else {
                        _launchPractice(context, item['title'] as String, item['route'] as String);
                      }
                    },
                    child: const Text('Open Session'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // TAB 3: MUDRAS & BANDHAS
  Widget _buildMudrasBandhasTab() {
    final List<Map<String, dynamic>> seals = [
      {
        'title': 'Gyan & Chin Mudra',
        'type': 'Hand Mudra',
        'desc': 'Tip of index finger meets tip of thumb, forming a circle of continuous consciousness. Gyan palms face upwards (receptivity); Chin palms face downwards (grounding).',
        'effect': 'Directs prana flow inward, stimulates brain memory circuits, relieves insomnia and dullness.',
      },
      {
        'title': 'Nasika Mudra (Vishnu Mudra)',
        'type': 'Hand Mudra',
        'desc': 'Right hand index and middle fingers folded toward palm; ring finger and thumb control the left and right nostrils during Nadi Shodhana.',
        'effect': 'Essential hand seal for alternate nostril breathing without leaking prana.',
      },
      {
        'title': 'Shanmukhi Mudra',
        'type': 'Face Mudra',
        'desc': 'Closing the six sensory doors: ears closed with thumbs, eyes with index fingers, nostrils with middle fingers, lips with ring and little fingers.',
        'effect': 'Deep sensory withdrawal (Pratyahara) and amplification of inner sound (Nada) during Bhramari.',
      },
      {
        'title': 'Jalandhara Bandha (Throat Lock)',
        'type': 'Energy Bandha',
        'desc': 'Chir touching chest between collarbones during breath retention. Spine stays straight.',
        'effect': 'Regulates carotid sinus blood pressure, balances thyroid, prevents prana escaping upward during Kumbhaka.',
      },
      {
        'title': 'Mula Bandha (Root Lock)',
        'type': 'Energy Bandha',
        'desc': 'Gentle contraction of the perineum/cervix area, lifting pelvic floor upward.',
        'effect': 'Prevents downward dissipation of Apana vayu; unites Prana and Apana in Sushumna nadi.',
      },
      {
        'title': 'Uddiyana Bandha (Abdominal Lift)',
        'type': 'Energy Bandha',
        'desc': 'Practiced on complete exhalation (Bahya Kumbhaka) on an empty stomach. Diaphragm is pulled up toward chest.',
        'effect': 'Massages internal viscera, stimulates solar plexus fire, directs prana upward.',
      },
      {
        'title': 'Maha Bandha (The Great Lock)',
        'type': 'Master Bandha',
        'desc': 'Simultaneous engagement of Jalandhara, Uddiyana, and Mula bandhas during external breath retention.',
        'effect': 'Awakens the central Sushumna channel and charges the entire bio-energetic body.',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: seals.length,
      itemBuilder: (context, index) {
        final item = seals[index];
        final bool isBandha = (item['type'] as String).contains('Bandha');

        return Card(
          color: AbhyasTheme.darkSurface,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AbhyasTheme.line),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isBandha ? Colors.deepOrange.withValues(alpha: 0.15) : AbhyasTheme.saffron.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item['type'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isBandha ? Colors.deepOrange : AbhyasTheme.saffron,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(item['desc'] as String, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                Text('• Energy Effect: ${item['effect']}', style: const TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 12)),
              ],
            ),
          ),
        );
      },
    );
  }

  // TAB 4: VEDIC RITUALS & MANTRAS
  Widget _buildRitualsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Preparatory Rituals',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AbhyasTheme.saffron),
        ),
        const SizedBox(height: 10),
        _buildRitualCard('Achamana (Purification)', 'Purification', 'Sip clean water 3 times to purify speech, body, and breath.', Icons.water_drop, Colors.blue, 'Om Keshavaya Namah, Om Narayanaya Namah, Om Madhavaya Namah.'),
        _buildRitualCard('Desha-Kala (Panchang)', 'Cosmic Time', 'Locate conscious awareness in astronomical time and space via the current Tithi and Nakshatra.', Icons.calendar_month, Colors.amber, 'Vedic sadhana begins with contemplation of Desha-Kala (cosmic time & space). Tuning to the day\'s lunar and solar phase harmonizes our biological prana.'),
        _buildRitualCard('Asana Sthapana', 'Seat of Practice', 'Establish a steady, comfortable seat (Sthira-Sukham Asanam) facing East or North.', Icons.chair_alt, Colors.brown, 'Place your asana (mat or wool blanket) cleanly. Sit with erect spine, shoulders soft, head centered.'),
        _buildRitualCard('Sankalp', 'Intention', 'Formulate a sacred resolve before beginning pranayama.', Icons.handshake, Colors.orange, 'I sit today for steadiness of prana, clarity of mind, and inner awakening.'),

        const SizedBox(height: 24),
        const Text(
          'Mantra & Invocation Library',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AbhyasTheme.saffron),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AbhyasTheme.darkSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AbhyasTheme.line),
          ),
          child: Column(
            children: [
              _buildMantraTile('Om Chanting (Pranava)', 'A-U-M. The primordial vibration resonating in the physical, astral, and causal bodies.'),
              const Divider(height: 1, color: AbhyasTheme.line),
              _buildMantraTile('Gayatri Mantra', 'ॐ भूर्भुवः स्वः तत्सवितुर्वरेण्यं भर्गो देवस्य धीमहि धियो यो नः प्रचोदयात् ॥'),
              const Divider(height: 1, color: AbhyasTheme.line),
              _buildMantraTile('Patanjali Invocation', 'योगेन चित्तस्य पदेन वाचां मलं शरीरस्य च वैद्यकेन । योऽपाकरोत्तं प्रवरं मुनीनां पतञ्जलिं प्राञ्जलिरानतोऽस्मि ॥'),
              const Divider(height: 1, color: AbhyasTheme.line),
              _buildMantraTile('Guru Vandana', 'गुरुर्ब्रह्मा गुरुर्विष्णुः गुरुर्देवो महेश्वरः । गुरुः साक्षात् परं ब्रह्म तस्मै श्रीगुरवे नमः ॥'),
              const Divider(height: 1, color: AbhyasTheme.line),
              _buildMantraTile('Shanti Path', 'ॐ सह नाववतु । सह नौ भुनक्तु । सह वीर्यं करवावहै । तेजस्वि नावधीतमस्तु मा विद्विषावहै । ॐ शान्तिः शान्तिः शान्तिः ॥'),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildRitualCard(String title, String subtitleTag, String description, IconData icon, Color color, String detail) {
    return Card(
      elevation: 0,
      color: AbhyasTheme.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AbhyasTheme.line),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(description, style: const TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 12)),
        trailing: const Icon(Icons.info_outline, color: Colors.grey, size: 18),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AbhyasTheme.darkSurface,
              title: Text(title, style: const TextStyle(color: AbhyasTheme.saffron, fontWeight: FontWeight.bold)),
              content: Text(detail, style: const TextStyle(color: Colors.white70)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close', style: TextStyle(color: AbhyasTheme.saffron)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMantraTile(String title, String text) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(text, style: const TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 12)),
      trailing: IconButton(
        icon: const Icon(Icons.volume_up, color: AbhyasTheme.saffron, size: 20),
        onPressed: () {
          _audioService.playBell(BellType.start);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Playing $title sound chime...')),
          );
        },
      ),
    );
  }
}
