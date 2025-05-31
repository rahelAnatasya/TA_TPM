import 'package:flutter/material.dart';

class FaqItem {
  final String question;
  final String answer;
  bool isExpanded;

  FaqItem({
    required this.question,
    required this.answer,
    this.isExpanded = false,
  });
}

class HelpFaqPage extends StatefulWidget {
  const HelpFaqPage({super.key});

  @override
  State<HelpFaqPage> createState() => _HelpFaqPageState();
}

class _HelpFaqPageState extends State<HelpFaqPage> {
  final List<FaqItem> _howToGuides = [
    FaqItem(
      question: 'Bagaimana cara Daftar dan Login?',
      answer:
          '1. Buka aplikasi Flora.\n'
          '2. Jika belum punya akun, ketuk "Daftar Sekarang" di halaman Login.\n'
          '3. Isi Nama Lengkap, Email, Password, dan (opsional) Alamat Anda, lalu ketuk "DAFTAR".\n'
          '4. Setelah berhasil daftar, Anda akan diarahkan ke halaman Login.\n'
          '5. Masukkan Email dan Password yang sudah terdaftar, lalu ketuk "LOGIN".',
    ),
    FaqItem(
      question: 'Bagaimana cara mencari dan melihat detail tanaman?',
      answer:
          '1. Di halaman utama (Toko), Anda dapat melihat daftar semua tanaman.\n'
          '2. Gulir ke bawah untuk melihat lebih banyak tanaman.\n'
          '3. Ketuk pada gambar atau nama tanaman untuk melihat detail lengkapnya, termasuk deskripsi, harga, ukuran, dan perawatan.',
    ),
    FaqItem(
      question:
          'Bagaimana cara menambahkan tanaman ke keranjang, melakukan "checkout", dan apa yang terjadi dengan alamat pengiriman?',
      answer:
          '1. Dari halaman detail tanaman, jika stok tersedia, ketuk tombol "Tambah Keranjang" atau "Beli Sekarang".\n'
          '2. Anda dapat melihat keranjang belanja dengan menavigasi ke tab "Keranjang". Di sana, Anda dapat mengatur jumlah item atau menghapusnya.\n'
          '3. Saat Anda melakukan "checkout" (baik dari "Beli Sekarang" di detail tanaman atau dari tombol "Checkout" di Keranjang Belanja):\n'
          '   - Alamat utama yang Anda daftarkan pada profil Anda akan secara otomatis digunakan sebagai alamat pengiriman untuk pesanan simulasi tersebut.\n'
          '   - Pastikan alamat di profil Anda sudah benar jika ingin alamat pengiriman yang sesuai tercatat di riwayat pembelian.\n'
          '4. Stok tanaman juga akan dikurangi (simulasi via API) setelah checkout berhasil.\n'
          '5. Saat ini, proses pembelian adalah simulasi dan akan dicatat dalam Riwayat Pembelian Anda. Tidak ada pembayaran nyata yang diproses.',
    ),
    FaqItem(
      question: 'Bagaimana cara menambahkan tanaman ke favorit?',
      answer:
          '1. Di halaman utama (Toko) pada setiap kartu tanaman, atau di halaman Detail Tanaman, Anda akan menemukan ikon hati.\n'
          '2. Ketuk ikon hati untuk menambahkan tanaman tersebut ke daftar favorit Anda.\n'
          '3. Ketuk lagi ikon hati yang sudah terisi untuk menghapusnya dari favorit.\n'
          '4. Anda dapat melihat semua tanaman favorit Anda di tab "Favorit".',
    ),
    FaqItem(
      question: 'Bagaimana cara mengelola profil dan akun saya?',
      answer:
          '1. Navigasi ke tab "Profil" (ikon orang di bagian bawah).\n'
          '2. Ketuk "Edit Profil" untuk mengubah Nama Lengkap, URL Foto Profil, dan Alamat Anda.\n'
          '3. Di halaman "Pengaturan Akun" (diakses dari Profil), Anda dapat:\n'
          '   - Mengubah alamat email Anda.\n'
          '   - Mengubah password Anda.\n'
          '   - Menghapus akun Anda secara permanen (memerlukan konfirmasi password).',
    ),
    FaqItem(
      question: 'Bagaimana cara melihat Riwayat Pembelian saya?',
      answer:
          '1. Navigasi ke tab "Profil".\n'
          '2. Ketuk opsi "Riwayat Pembelian".\n'
          '3. Halaman ini akan menampilkan daftar semua simulasi pembelian yang telah Anda lakukan, beserta detail item, totalnya, dan alamat pengiriman yang digunakan saat itu (berdasarkan alamat profil Anda saat pemesanan).',
    ),
  ];

  final List<FaqItem> _otherFaqs = [
    FaqItem(
      question: 'Metode pembayaran apa saja yang diterima?',
      answer:
          'Saat ini, aplikasi Flora hanya menyediakan simulasi proses belanja dan pencatatan riwayat. Tidak ada pembayaran nyata yang diproses. Di masa mendatang, kami berencana untuk mengintegrasikan berbagai metode pembayaran online.',
    ),
    FaqItem(
      question: 'Bagaimana proses pengiriman tanaman?',
      answer:
          'Karena ini adalah aplikasi demo/simulasi, tidak ada pengiriman fisik yang dilakukan. Alamat pengiriman yang tercatat pada riwayat pembelian Anda diambil dari alamat yang Anda atur di profil Anda pada saat pemesanan.',
    ),
    FaqItem(
      question: 'Apakah saya bisa mengembalikan tanaman yang sudah dibeli?',
      answer:
          'Kebijakan pengembalian akan dijelaskan secara rinci ketika fitur pembelian nyata diimplementasikan. Umumnya, pengembalian tanaman hidup memiliki syarat dan ketentuan khusus. Untuk saat ini, karena pembelian bersifat simulasi, tidak ada proses pengembalian.',
    ),
    FaqItem(
      question: 'Bagaimana jika saya lupa password?',
      answer:
          'Fitur "Lupa Password" untuk reset password saat ini belum tersedia. Pastikan Anda mengingat password Anda. Jika Anda sudah login, Anda dapat mengubah password Anda melalui menu "Pengaturan Akun" di halaman Profil.',
    ),
    FaqItem(
      question: 'Bagaimana alamat saya digunakan?',
      answer:
          'Alamat yang Anda masukkan di profil akan digunakan sebagai alamat pengiriman default untuk setiap pesanan (simulasi) yang Anda buat. Alamat ini akan tercatat dalam riwayat pembelian Anda.',
    ),
    FaqItem(
      question: 'Bagaimana jika saya mengubah alamat di profil saya?',
      answer:
          'Jika Anda mengubah alamat di profil Anda, pesanan yang sudah tercatat sebelumnya di Riwayat Pembelian akan tetap menggunakan alamat yang tercatat pada saat pemesanan tersebut. Perubahan alamat di profil hanya akan berlaku untuk pesanan-pesanan baru setelah perubahan dilakukan.',
    ),
    FaqItem(
      question: 'Apa yang terjadi jika saya mengubah alamat email saya?',
      answer:
          'Jika Anda mengubah alamat email melalui "Pengaturan Akun":\n'
          '1. Email login Anda akan berubah ke alamat email yang baru.\n'
          '2. Data favorit dan keranjang belanja Anda disimpan berdasarkan alamat email. Dengan mengubah email, data favorit dan keranjang dari email lama Anda mungkin tidak akan terbawa ke sesi email baru. Efektifnya, Anda akan memulai dengan daftar favorit dan keranjang kosong untuk email baru tersebut.',
    ),
    FaqItem(
      question: 'Apa yang terjadi jika saya menghapus akun saya?',
      answer:
          'Menghapus akun adalah tindakan permanen:\n'
          '1. Anda akan diminta memasukkan password saat ini untuk konfirmasi.\n'
          '2. Semua data profil Anda (nama, email, password terenkripsi, URL foto, alamat) akan dihapus dari database.\n'
          '3. Riwayat pembelian Anda yang terkait dengan akun tersebut juga akan dihapus.\n'
          '4. Data favorit dan keranjang belanja yang tersimpan akan dihapus.\n'
          '5. Anda akan otomatis logout dan tidak bisa login kembali dengan akun tersebut. Data tidak dapat dipulihkan.',
    ),
  ];

  Widget _buildFaqSection(String title, List<FaqItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: 20.0,
            bottom: 8.0,
            left: 16.0,
            right: 16.0,
          ),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 6.0,
              ),
              elevation: 2.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                key: PageStorageKey(items[index].question),
                title: Text(
                  items[index].question,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                onExpansionChanged: (bool expanding) {
                  setState(() {
                    items[index].isExpanded = expanding;
                  });
                },
                initiallyExpanded: items[index].isExpanded,
                childrenPadding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  bottom: 16.0,
                  top: 0,
                ),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      items[index].answer,
                      style: TextStyle(
                        fontSize: 14.5,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bantuan & FAQ')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildFaqSection('Panduan Penggunaan Aplikasi', _howToGuides),
            _buildFaqSection('Pertanyaan Umum (FAQ)', _otherFaqs),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
