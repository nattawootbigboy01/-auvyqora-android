import '../models/drama.dart';
import '../models/episode.dart';

const sampleCatalog = <Drama>[
  Drama(id: 'drama-001', title: 'เสียงสุดท้าย', genre: 'ลึกลับ · ดราม่า', isFeatured: true, synopsis: 'เมื่อเสียงปริศนาจากอดีตกลับมาดังอีกครั้ง ทุกความลับที่ถูกฝังไว้กำลังรอวันเปิดเผย', episodes: [Episode(id: 'ep-001-01', title: 'เสียงที่ไม่มีใครได้ยิน', number: 1, durationLabel: '2 นาที'), Episode(id: 'ep-001-02', title: 'ข้อความจากคนตาย', number: 2, durationLabel: '2 นาที'), Episode(id: 'ep-001-03', title: 'ห้องที่ถูกล็อก', number: 3, durationLabel: '3 นาที')]),
  Drama(id: 'drama-002', title: 'รักในเงาจันทร์', genre: 'โรแมนติก · ดราม่า', synopsis: 'คำสัญญาในคืนหนึ่งเปลี่ยนชีวิตของคนสองคนไปตลอดกาล', episodes: [Episode(id: 'ep-002-01', title: 'คืนแรก', number: 1), Episode(id: 'ep-002-02', title: 'ความจริง', number: 2)]),
  Drama(id: 'drama-003', title: 'เกมลวงบ่วงแค้น', genre: 'ระทึกขวัญ', synopsis: 'ผู้เล่นทุกคนมีความลับ และไม่มีใครออกจากเกมนี้ได้โดยไม่สูญเสียบางอย่าง', episodes: [Episode(id: 'ep-003-01', title: 'เริ่มเกม', number: 1)]),
];
