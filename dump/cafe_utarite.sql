-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Waktu pembuatan: 31 Des 2025 pada 05.27
-- Versi server: 10.4.28-MariaDB
-- Versi PHP: 8.2.4

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `cafe utarite benar`
--

DELIMITER $$
--
-- Prosedur
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_proses_pembayaran` (IN `p_pesanan_id` BIGINT, IN `p_karyawan_id` BIGINT, IN `p_metode` ENUM('tunai','non_tunai'), IN `p_jumlah_bayar` DECIMAL(12,2), IN `p_nomor_refrensi` VARCHAR(100))   BEGIN
  DECLARE v_total DECIMAL(12,2);
  DECLARE v_status ENUM('Lunas','Belum Lunas');
  DECLARE v_new_pembayaran_id BIGINT;

  DECLARE exit handler FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;

    INSERT INTO audit_event_log(actor_user, event_type, table_name, ref_id, detail)
    VALUES (
      CURRENT_USER(),
      'PAYMENT_FAILED',
      'pembayaran',
      p_pesanan_id,
      'Rollback: error saat sp_proses_pembayaran.'
    );

    RESIGNAL;
  END;

  START TRANSACTION;

  -- Pastikan pesanan ada & ambil total
  SELECT total_pesanan INTO v_total
  FROM pesanan
  WHERE pesanan_id = p_pesanan_id
  LIMIT 1;

  IF v_total IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Pesanan tidak ditemukan untuk pembayaran.';
  END IF;

  -- Status pembayaran otomatis
  IF p_jumlah_bayar >= v_total THEN
    SET v_status = 'Lunas';
  ELSE
    SET v_status = 'Belum Lunas';
  END IF;

  -- Antisipasi kalau pembayaran_id juga tidak auto increment: pakai MAX+1
  SET v_new_pembayaran_id := (SELECT COALESCE(MAX(pembayaran_id), 0) + 1 FROM pembayaran);

  -- Insert pembayaran (nilai ENUM valid)
  INSERT INTO pembayaran
    (pembayaran_id, pesanan_id, tanggal_pembayaran, metode_pembayaran, jumlah_bayar,
     nomor_refrensi, status_pembayaran, karyawan_id)
  VALUES
    (v_new_pembayaran_id, p_pesanan_id, NOW(), p_metode, p_jumlah_bayar,
     p_nomor_refrensi, v_status, p_karyawan_id);

  COMMIT;
END$$

--
-- Fungsi
--
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_test` (`x` INT) RETURNS INT(11) DETERMINISTIC BEGIN
  RETURN x + 1;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Struktur dari tabel `audit_event_log`
--

CREATE TABLE `audit_event_log` (
  `log_id` bigint(20) NOT NULL,
  `event_time` datetime NOT NULL DEFAULT current_timestamp(),
  `actor_user` varchar(128) NOT NULL,
  `event_type` varchar(50) NOT NULL,
  `table_name` varchar(64) NOT NULL,
  `ref_id` bigint(20) DEFAULT NULL,
  `detail` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `audit_event_log`
--

INSERT INTO `audit_event_log` (`log_id`, `event_time`, `actor_user`, `event_type`, `table_name`, `ref_id`, `detail`) VALUES
(1, '2025-12-21 14:21:37', 'root@localhost', 'STOCK_DECREASE', 'detail_pesanan', 10, 'produk_id=1, qty=2'),
(2, '2025-12-21 14:25:36', 'root@localhost', 'STOCK_DECREASE', 'detail_pesanan', 202, 'produk_id=1, qty=2'),
(3, '2025-12-21 14:59:24', 'root@localhost', 'STOCK_DECREASE', 'detail_pesanan', 203, 'produk_id=1, qty=2'),
(4, '2025-12-21 17:22:10', 'root@localhost', 'STOCK_DECREASE', 'detail_pesanan', 204, 'produk_id=1, qty=2'),
(5, '2025-12-21 17:26:49', 'root@localhost', 'STOCK_DECREASE', 'detail_pesanan', 205, 'produk_id=1, qty=2'),
(6, '2025-12-21 17:37:40', 'root@localhost', 'PAYMENT_FAILED', 'pembayaran', NULL, 'Rollback: error saat sp_proses_pembayaran.'),
(7, '2025-12-21 18:18:11', 'root@localhost', 'STOCK_DECREASE', 'detail_pesanan', 206, 'produk_id=1, qty=2'),
(8, '2025-12-21 18:18:11', 'root@localhost', 'PAYMENT_INSERT', 'pembayaran', 201, 'pesanan_id=206, metode=non_tunai, jumlah_bayar=50000, status=Lunas'),
(9, '2025-12-21 18:21:19', 'root@localhost', 'STOCK_DECREASE', 'detail_pesanan', 207, 'produk_id=1, qty=2'),
(10, '2025-12-21 18:21:19', 'root@localhost', 'PAYMENT_INSERT', 'pembayaran', 202, 'pesanan_id=207, metode=non_tunai, jumlah_bayar=50000, status=Lunas');

-- --------------------------------------------------------

--
-- Struktur dari tabel `audit_event_unlog`
--

CREATE TABLE `audit_event_unlog` (
  `event_time` datetime NOT NULL DEFAULT current_timestamp(),
  `actor_user` varchar(128) NOT NULL,
  `event_type` varchar(50) NOT NULL,
  `table_name` varchar(64) NOT NULL,
  `ref_id` bigint(20) DEFAULT NULL,
  `detail` varchar(255) DEFAULT NULL
) ENGINE=MEMORY DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `bah_makanan`
--

CREATE TABLE `bah_makanan` (
  `jenis_makanan` varchar(100) NOT NULL,
  `tanggal_kadaluwarsa` date NOT NULL,
  `jumlah` int(11) NOT NULL,
  `id_jenis_produk` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `bah_makanan`
--

INSERT INTO `bah_makanan` (`jenis_makanan`, `tanggal_kadaluwarsa`, `jumlah`, `id_jenis_produk`) VALUES
('Apel', '2025-06-06', 75, 5),
('Ayam', '2025-08-01', 47, 9),
('Brokoli', '2025-06-22', 65, 4),
('Ikan', '2026-04-05', 16, 5),
('Kacang Hijau', '2026-03-07', 70, 10),
('Kacang Merah', '2025-06-16', 19, 9),
('Keju', '2026-04-06', 48, 1),
('Kentang', '2025-05-29', 60, 3),
('Nasi', '2025-07-07', 36, 4),
('Pisang', '2026-03-23', 42, 10),
('Roti Tawar', '2026-04-30', 10, 4),
('Sayur Bayam', '2025-08-29', 81, 4),
('Susu UHT', '2026-01-27', 87, 9),
('Tahu', '2025-10-18', 26, 9),
('Telur', '2025-06-22', 4, 5),
('Tempe', '2026-02-22', 88, 7),
('Timun', '2026-02-18', 66, 10),
('Tomat', '2025-08-23', 76, 9),
('Wortel', '2025-07-29', 76, 5),
('Yogurt', '2026-02-15', 20, 4);

-- --------------------------------------------------------

--
-- Struktur dari tabel `detail_pembelian`
--

CREATE TABLE `detail_pembelian` (
  `detail_id` int(11) NOT NULL,
  `pembelian_id` int(11) DEFAULT NULL,
  `produk_id` int(11) DEFAULT NULL,
  `jumlah` int(11) DEFAULT NULL,
  `harga_total` decimal(12,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `detail_pembelian`
--

INSERT INTO `detail_pembelian` (`detail_id`, `pembelian_id`, `produk_id`, `jumlah`, `harga_total`) VALUES
(1, 38, 44, 9, 10113.23),
(2, 12, 6, 1, 101415.21),
(3, 13, 8, 7, 936183.68),
(4, 21, 38, 3, 529302.68),
(5, 43, 29, 3, 914822.40),
(6, 24, 42, 2, 148983.07),
(7, 33, 23, 10, 968578.96),
(8, 23, 2, 1, 895660.60),
(9, 9, 25, 4, 178132.12),
(10, 9, 31, 8, 426896.55),
(11, 22, 50, 10, 205575.39),
(12, 25, 50, 5, 418413.45),
(13, 42, 19, 1, 750684.00),
(14, 48, 35, 8, 229903.30),
(15, 26, 41, 7, 909509.55),
(16, 40, 24, 5, 529551.38),
(17, 20, 39, 9, 911343.90),
(18, 11, 24, 8, 578376.43),
(19, 29, 11, 1, 111311.08),
(20, 2, 50, 4, 545194.50),
(21, 14, 7, 5, 148566.46),
(22, 3, 13, 6, 884294.22),
(23, 14, 9, 5, 383808.50),
(24, 40, 8, 5, 367648.41),
(25, 19, 33, 8, 693302.54),
(26, 8, 25, 5, 362966.41),
(27, 2, 31, 10, 21552.50),
(28, 34, 3, 8, 73426.66),
(29, 33, 42, 3, 386005.25),
(30, 3, 8, 8, 577942.69),
(31, 16, 6, 2, 161400.52),
(32, 49, 23, 6, 711952.10),
(33, 34, 21, 1, 276311.04),
(34, 26, 22, 8, 79380.68),
(35, 20, 26, 2, 933269.51),
(36, 21, 44, 7, 757908.42),
(37, 16, 25, 10, 523673.26),
(38, 6, 37, 6, 116291.65),
(39, 41, 14, 2, 295830.65),
(40, 14, 41, 8, 132931.58),
(41, 43, 46, 4, 574365.99),
(42, 15, 47, 1, 28460.82),
(43, 12, 36, 6, 720217.69),
(44, 3, 21, 4, 864906.44),
(45, 33, 29, 8, 145090.67),
(46, 29, 31, 9, 54106.36),
(47, 33, 9, 5, 620165.66),
(48, 16, 42, 1, 22430.42),
(49, 25, 50, 5, 572419.46),
(50, 31, 28, 4, 746387.60),
(51, 27, 44, 7, 377422.56),
(52, 48, 47, 4, 498832.02),
(53, 37, 33, 4, 894091.00),
(54, 20, 38, 7, 49286.67),
(55, 6, 16, 2, 460729.64),
(56, 43, 11, 3, 583947.77),
(57, 31, 18, 5, 223493.78),
(58, 15, 18, 8, 140944.60),
(59, 29, 23, 7, 633420.33),
(60, 14, 7, 10, 170583.46),
(61, 49, 45, 10, 201499.94),
(62, 23, 17, 4, 925559.89),
(63, 29, 48, 5, 774456.25),
(64, 22, 47, 4, 432542.73),
(65, 17, 47, 7, 949526.16),
(66, 15, 14, 10, 17922.68),
(67, 22, 47, 6, 457481.59),
(68, 13, 13, 9, 613114.92),
(69, 13, 8, 8, 135066.22),
(70, 44, 13, 3, 22585.54),
(71, 49, 6, 3, 340843.37),
(72, 27, 6, 10, 508045.15),
(73, 28, 44, 2, 351289.29),
(74, 31, 33, 5, 880043.66),
(75, 1, 23, 3, 966069.54),
(76, 7, 13, 8, 800617.56),
(77, 48, 49, 7, 603119.20),
(78, 24, 23, 3, 226209.30),
(79, 43, 32, 6, 242915.65),
(80, 25, 46, 7, 199347.67),
(81, 13, 19, 10, 425991.74),
(82, 17, 31, 4, 581134.92),
(83, 36, 42, 2, 262155.73),
(84, 30, 37, 1, 578964.39),
(85, 29, 3, 4, 702885.19),
(86, 37, 37, 9, 46105.01),
(87, 39, 47, 9, 329454.19),
(88, 49, 38, 3, 388281.72),
(89, 15, 12, 9, 625700.17),
(90, 17, 29, 6, 681022.88),
(91, 41, 43, 7, 349912.78),
(92, 15, 37, 8, 935523.48),
(93, 33, 47, 2, 305812.23),
(94, 1, 23, 2, 804139.47),
(95, 19, 28, 6, 523821.51),
(96, 31, 47, 8, 349262.02),
(97, 40, 30, 9, 189796.72),
(98, 41, 49, 8, 691529.12),
(99, 1, 40, 2, 472211.22),
(100, 11, 29, 10, 848552.06),
(101, 29, 16, 1, 704663.63),
(102, 12, 39, 6, 70296.73),
(103, 3, 16, 2, 961861.49),
(104, 39, 28, 2, 214745.73),
(105, 21, 24, 1, 878325.23),
(106, 2, 36, 5, 319521.31),
(107, 28, 12, 8, 356231.04),
(108, 21, 45, 9, 163421.80),
(109, 16, 22, 10, 881856.98),
(110, 24, 47, 7, 539526.49),
(111, 20, 13, 1, 46153.10),
(112, 11, 31, 7, 728656.29),
(113, 33, 32, 1, 577794.31),
(114, 6, 48, 8, 463516.09),
(115, 41, 22, 5, 332569.04),
(116, 14, 26, 6, 184900.33),
(117, 22, 44, 6, 501414.20),
(118, 31, 11, 6, 588615.40),
(119, 12, 8, 1, 500490.48),
(120, 25, 6, 1, 621287.64),
(121, 40, 36, 5, 364315.62),
(122, 34, 24, 4, 578425.72),
(123, 27, 31, 10, 173787.09),
(124, 14, 41, 10, 142157.25),
(125, 6, 45, 8, 480168.67),
(126, 13, 36, 8, 95536.00),
(127, 14, 14, 9, 429100.40),
(128, 24, 37, 3, 409567.09),
(129, 21, 3, 9, 251174.76),
(130, 16, 41, 9, 766542.71),
(131, 26, 7, 7, 734064.87),
(132, 42, 3, 1, 50767.85),
(133, 21, 9, 3, 855162.41),
(134, 1, 7, 10, 149832.95),
(135, 30, 29, 10, 339431.60),
(136, 37, 19, 1, 395835.68),
(137, 14, 6, 5, 72624.23),
(138, 17, 14, 10, 659249.96),
(139, 26, 17, 6, 69681.08),
(140, 6, 17, 7, 961089.14),
(141, 20, 45, 6, 536076.26),
(142, 8, 21, 4, 33256.09),
(143, 40, 49, 3, 110872.12),
(144, 12, 18, 2, 540377.87),
(145, 8, 47, 3, 84015.60),
(146, 14, 19, 1, 661138.55),
(147, 24, 30, 7, 600667.26),
(148, 20, 41, 10, 460063.53),
(149, 14, 17, 4, 588856.02),
(150, 36, 21, 3, 766380.78),
(151, 40, 9, 10, 951241.38),
(152, 40, 2, 5, 842217.48),
(153, 26, 19, 8, 123871.82),
(154, 38, 16, 6, 446136.60),
(155, 29, 17, 3, 414369.68),
(156, 38, 44, 4, 73672.99),
(157, 34, 50, 2, 511513.65),
(158, 17, 11, 9, 629476.56),
(159, 23, 42, 6, 550842.67),
(160, 17, 36, 9, 24938.19),
(161, 39, 35, 6, 11583.61),
(162, 27, 9, 1, 800799.38),
(163, 36, 46, 6, 802481.87),
(164, 7, 26, 2, 543984.32),
(165, 28, 28, 10, 345950.44),
(166, 28, 16, 6, 398029.47),
(167, 49, 9, 2, 630960.06),
(168, 19, 37, 6, 114204.21),
(169, 39, 11, 7, 814680.50),
(170, 39, 30, 7, 561088.93),
(171, 19, 8, 5, 659816.59),
(172, 36, 46, 7, 765728.98),
(173, 7, 46, 3, 104403.33),
(174, 22, 21, 7, 475198.20),
(175, 30, 2, 7, 39735.85),
(176, 17, 38, 9, 158698.79),
(177, 22, 19, 8, 753255.96),
(178, 40, 45, 6, 118980.53),
(179, 28, 16, 7, 934864.43),
(180, 21, 31, 9, 643468.97),
(181, 26, 31, 6, 612125.19),
(182, 12, 41, 10, 648981.72),
(183, 9, 45, 1, 779215.52),
(184, 42, 11, 9, 143012.84),
(185, 16, 46, 3, 382515.32),
(186, 41, 12, 4, 228327.28),
(187, 48, 23, 10, 231907.48),
(188, 14, 17, 9, 268664.17),
(189, 36, 11, 8, 755003.57),
(190, 9, 31, 8, 342567.35),
(191, 9, 42, 4, 61375.55),
(192, 42, 30, 5, 785460.16),
(193, 1, 39, 7, 172772.20),
(194, 14, 29, 8, 755241.21),
(195, 48, 46, 8, 368814.60),
(196, 31, 23, 5, 49546.34),
(197, 28, 29, 1, 597371.56),
(198, 25, 44, 5, 543287.47),
(199, 2, 45, 9, 496583.42),
(200, 11, 45, 8, 439158.13);

-- --------------------------------------------------------

--
-- Struktur dari tabel `detail_pesanan`
--

CREATE TABLE `detail_pesanan` (
  `detail_id` int(11) NOT NULL,
  `pesanan_id` int(11) DEFAULT NULL,
  `produk_id` int(11) DEFAULT NULL,
  `jumlah` int(11) DEFAULT NULL,
  `subtotal` decimal(12,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `detail_pesanan`
--

INSERT INTO `detail_pesanan` (`detail_id`, `pesanan_id`, `produk_id`, `jumlah`, `subtotal`) VALUES
(1, 41, 16, 9, 447782.00),
(2, 44, 19, 9, 971799.00),
(3, 35, 50, 6, 342847.00),
(4, 32, 27, 5, 182156.00),
(5, 38, 40, 4, 121718.00),
(6, 5, 43, 4, 778359.00),
(7, 39, 43, 2, 423242.00),
(8, 4, 6, 9, 521684.00),
(9, 47, 7, 4, 982921.00),
(10, 32, 3, 1, 650564.00),
(11, 47, 13, 3, 677780.00),
(12, 27, 16, 2, 941623.00),
(13, 47, 9, 3, 730365.00),
(14, 16, 42, 9, 954887.00),
(15, 18, 23, 9, 565514.00),
(16, 10, 42, 4, 993136.00),
(17, 44, 33, 3, 33432.00),
(18, 13, 11, 9, 696114.00),
(19, 10, 38, 7, 459622.00),
(20, 7, 20, 9, 406754.00),
(21, 2, 5, 9, 20321.00),
(22, 7, 38, 2, 34466.00),
(23, 21, 27, 8, 531110.00),
(24, 44, 38, 9, 298986.00),
(25, 36, 28, 1, 244000.00),
(26, 22, 44, 1, 162902.00),
(27, 11, 38, 2, 246175.00),
(28, 31, 14, 8, 587515.00),
(29, 48, 21, 4, 268454.00),
(30, 50, 37, 1, 720206.00),
(31, 41, 29, 5, 320335.00),
(32, 12, 47, 3, 486361.00),
(33, 8, 50, 10, 854626.00),
(34, 2, 16, 1, 122103.00),
(35, 50, 41, 10, 995579.00),
(36, 15, 31, 1, 917127.00),
(37, 17, 22, 3, 133925.00),
(38, 43, 50, 4, 96525.00),
(39, 29, 34, 9, 556411.00),
(40, 23, 25, 2, 363195.00),
(41, 6, 8, 1, 552057.00),
(42, 29, 16, 2, 664757.00),
(43, 32, 35, 1, 682042.00),
(44, 49, 37, 7, 800547.00),
(45, 32, 18, 9, 251445.00),
(46, 10, 22, 5, 893442.00),
(47, 40, 41, 8, 583274.00),
(48, 37, 41, 7, 909091.00),
(49, 9, 15, 6, 324417.00),
(50, 28, 4, 3, 680998.00),
(51, 6, 6, 3, 352373.00),
(52, 30, 13, 7, 181633.00),
(53, 45, 6, 1, 13781.00),
(54, 27, 20, 8, 582005.00),
(55, 26, 37, 6, 596002.00),
(56, 23, 30, 1, 171733.00),
(57, 24, 34, 7, 318807.00),
(58, 33, 50, 3, 793325.00),
(59, 16, 46, 5, 174698.00),
(60, 17, 7, 7, 810152.00),
(61, 7, 44, 10, 206501.00),
(62, 50, 22, 10, 63924.00),
(63, 42, 41, 4, 185620.00),
(64, 35, 13, 5, 220983.00),
(65, 22, 2, 4, 492972.00),
(66, 24, 37, 6, 901217.00),
(67, 19, 29, 4, 262266.00),
(68, 39, 11, 2, 65170.00),
(69, 39, 33, 6, 701148.00),
(70, 20, 19, 9, 643867.00),
(71, 42, 24, 4, 733772.00),
(72, 17, 5, 7, 475085.00),
(73, 35, 24, 10, 894115.00),
(74, 34, 32, 2, 507369.00),
(75, 10, 1, 9, 787584.00),
(76, 11, 9, 6, 841075.00),
(77, 41, 47, 4, 426718.00),
(78, 16, 50, 7, 593649.00),
(79, 35, 32, 2, 444589.00),
(80, 35, 34, 4, 593949.00),
(81, 13, 48, 4, 545533.00),
(82, 45, 3, 4, 708674.00),
(83, 27, 11, 4, 51514.00),
(84, 4, 30, 1, 774908.00),
(85, 6, 11, 2, 10722.00),
(86, 2, 23, 3, 416414.00),
(87, 47, 50, 4, 552958.00),
(88, 48, 23, 4, 789945.00),
(89, 1, 31, 5, 771698.00),
(90, 12, 22, 6, 306987.00),
(91, 20, 10, 2, 80568.00),
(92, 16, 48, 2, 878548.00),
(93, 39, 14, 3, 726166.00),
(94, 24, 22, 1, 199585.00),
(95, 38, 7, 10, 551310.00),
(96, 30, 48, 9, 596744.00),
(97, 35, 23, 1, 409254.00),
(98, 27, 1, 5, 481475.00),
(99, 24, 48, 1, 812287.00),
(100, 10, 47, 3, 331770.00),
(101, 10, 34, 1, 358297.32),
(102, 44, 47, 2, 350981.76),
(103, 19, 10, 3, 169570.60),
(104, 29, 11, 8, 627852.89),
(105, 8, 33, 4, 800175.74),
(106, 7, 19, 7, 939775.45),
(107, 13, 35, 9, 897571.16),
(108, 34, 15, 8, 851141.93),
(109, 42, 35, 2, 990340.01),
(110, 34, 8, 3, 105851.15),
(111, 16, 3, 10, 230818.03),
(112, 16, 42, 2, 752426.56),
(113, 13, 11, 5, 108275.58),
(114, 28, 23, 5, 712915.02),
(115, 45, 47, 8, 906729.27),
(116, 32, 38, 7, 312030.55),
(117, 36, 24, 8, 265316.21),
(118, 20, 18, 6, 378981.20),
(119, 17, 21, 1, 37409.03),
(120, 6, 24, 8, 781554.07),
(121, 40, 40, 3, 477947.14),
(122, 38, 41, 3, 30551.69),
(123, 8, 48, 7, 731076.42),
(124, 49, 27, 2, 220794.34),
(125, 28, 37, 2, 755195.02),
(126, 33, 16, 4, 890723.01),
(127, 49, 42, 9, 699474.11),
(128, 18, 46, 4, 352308.85),
(129, 50, 18, 7, 481232.91),
(130, 38, 37, 10, 119534.82),
(131, 12, 9, 4, 634083.27),
(132, 40, 9, 6, 605119.57),
(133, 30, 14, 5, 816402.13),
(134, 31, 18, 10, 916507.14),
(135, 49, 38, 5, 365145.75),
(136, 16, 37, 8, 418643.98),
(137, 31, 46, 4, 810570.41),
(138, 30, 22, 4, 384612.00),
(139, 43, 27, 1, 978644.83),
(140, 48, 27, 9, 321546.57),
(141, 1, 32, 9, 860946.80),
(142, 2, 46, 2, 699296.41),
(143, 34, 42, 1, 730833.52),
(144, 41, 9, 3, 392119.88),
(145, 1, 3, 3, 365392.99),
(146, 17, 16, 6, 876268.08),
(147, 44, 7, 4, 895651.06),
(148, 32, 5, 10, 251531.18),
(149, 27, 3, 8, 496011.38),
(150, 26, 33, 9, 742371.61),
(151, 16, 18, 3, 171141.84),
(152, 38, 38, 1, 407555.62),
(153, 40, 22, 7, 424732.10),
(154, 15, 48, 5, 310123.45),
(155, 47, 3, 7, 308748.13),
(156, 16, 1, 3, 401975.67),
(157, 42, 41, 10, 94058.84),
(158, 19, 30, 2, 237432.36),
(159, 18, 1, 1, 306856.47),
(160, 39, 33, 1, 698684.82),
(161, 11, 30, 8, 804470.98),
(162, 21, 27, 1, 81188.94),
(163, 26, 24, 1, 756200.61),
(164, 43, 35, 10, 66371.27),
(165, 32, 5, 4, 294274.43),
(166, 7, 2, 4, 85130.18),
(167, 48, 25, 5, 353966.67),
(168, 20, 38, 1, 857054.33),
(169, 15, 41, 7, 329974.48),
(170, 43, 21, 8, 389207.42),
(171, 10, 25, 3, 884031.44),
(172, 24, 20, 4, 97407.58),
(173, 4, 19, 1, 905901.29),
(174, 47, 38, 2, 547853.67),
(175, 44, 2, 10, 743166.89),
(176, 17, 16, 2, 393275.75),
(177, 18, 5, 6, 629897.29),
(178, 4, 9, 8, 422076.84),
(179, 11, 13, 3, 890547.08),
(180, 38, 42, 10, 440131.24),
(181, 41, 7, 8, 898797.54),
(182, 33, 16, 9, 939087.38),
(183, 47, 14, 5, 401064.98),
(184, 35, 32, 4, 572571.60),
(185, 17, 23, 3, 644583.98),
(186, 45, 2, 1, 969159.13),
(187, 39, 47, 9, 473083.77),
(188, 29, 21, 2, 890514.22),
(189, 12, 46, 2, 137522.12),
(190, 12, 16, 5, 847586.45),
(191, 39, 40, 4, 47802.59),
(192, 15, 50, 3, 15051.47),
(193, 23, 31, 6, 510221.25),
(194, 26, 11, 10, 617088.64),
(195, 29, 42, 9, 883164.31),
(196, 38, 28, 10, 18867.54),
(197, 39, 27, 10, 908394.04),
(198, 13, 28, 3, 732584.87),
(199, 20, 15, 2, 190834.39),
(200, 42, 22, 3, 132033.20),
(201, 10, 1, 2, 100000.00),
(202, 202, 1, 2, 100000.00),
(203, 203, 1, 2, 100000.00),
(204, 204, 1, 2, 100000.00),
(205, 205, 1, 2, 100000.00),
(206, 206, 1, 2, 100000.00),
(207, 207, 1, 2, 100000.00);

--
-- Trigger `detail_pesanan`
--
DELIMITER $$
CREATE TRIGGER `ad_detail_pesanan_restore_stock` AFTER DELETE ON `detail_pesanan` FOR EACH ROW BEGIN
  UPDATE produk
  SET stok = stok + OLD.jumlah
  WHERE produk_id = OLD.produk_id;

  -- (OPSIONAL) kalau ada tabel gudang_stok, balikin juga
  -- DECLARE v_gudang_id BIGINT;
  -- SELECT gudang_id INTO v_gudang_id
  -- FROM produk
  -- WHERE produk_id = OLD.produk_id
  -- LIMIT 1;
  --
  -- UPDATE gudang_stok
  -- SET stok = stok + OLD.jumlah
  -- WHERE gudang_id = v_gudang_id AND produk_id = OLD.produk_id;

  INSERT INTO audit_event_log(actor_user, event_type, table_name, ref_id, detail)
  VALUES (
    CURRENT_USER(),
    'STOCK_RESTORE',
    'detail_pesanan',
    OLD.pesanan_id,
    CONCAT('produk_id=', OLD.produk_id, ', qty=', OLD.jumlah)
  );

  INSERT INTO audit_event_unlog(actor_user, event_type, table_name, ref_id, detail)
  VALUES (
    CURRENT_USER(),
    'STOCK_RESTORE',
    'detail_pesanan',
    OLD.pesanan_id,
    CONCAT('produk_id=', OLD.produk_id)
  );
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `ai_detail_pesanan_reduce_stock` AFTER INSERT ON `detail_pesanan` FOR EACH ROW BEGIN
  -- kurangi stok di tabel produk
  UPDATE produk
  SET stok = stok - NEW.jumlah
  WHERE produk_id = NEW.produk_id;

  -- (OPSIONAL) kalau kamu punya tabel stok gudang terpisah, aktifkan bagian ini
  -- Contoh asumsi tabel: gudang_stok(gudang_id, produk_id, stok)
  -- DECLARE v_gudang_id BIGINT;
  -- SELECT gudang_id INTO v_gudang_id
  -- FROM produk
  -- WHERE produk_id = NEW.produk_id
  -- LIMIT 1;
  --
  -- UPDATE gudang_stok
  -- SET stok = stok - NEW.jumlah
  -- WHERE gudang_id = v_gudang_id AND produk_id = NEW.produk_id;

  -- logging (kalau kamu sudah bikin audit tables)
  INSERT INTO audit_event_log(actor_user, event_type, table_name, ref_id, detail)
  VALUES (
    CURRENT_USER(),
    'STOCK_DECREASE',
    'detail_pesanan',
    NEW.pesanan_id,
    CONCAT('produk_id=', NEW.produk_id, ', qty=', NEW.jumlah)
  );

  INSERT INTO audit_event_unlog(actor_user, event_type, table_name, ref_id, detail)
  VALUES (
    CURRENT_USER(),
    'STOCK_DECREASE',
    'detail_pesanan',
    NEW.pesanan_id,
    CONCAT('produk_id=', NEW.produk_id)
  );
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `bi_detail_pesanan_check_stock` BEFORE INSERT ON `detail_pesanan` FOR EACH ROW BEGIN
  DECLARE v_stok INT;

  SELECT stok INTO v_stok
  FROM produk
  WHERE produk_id = NEW.produk_id
  LIMIT 1;

  IF v_stok IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Produk tidak ditemukan.';
  END IF;

  IF NEW.jumlah <= 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Jumlah harus > 0.';
  END IF;

  IF v_stok < NEW.jumlah THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Stok tidak cukup untuk produk ini.';
  END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struktur dari tabel `gudang`
--

CREATE TABLE `gudang` (
  `gudang_id` int(11) NOT NULL,
  `lokasi` varchar(100) DEFAULT NULL,
  `kapasitas` int(11) DEFAULT NULL,
  `manajer` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `gudang`
--

INSERT INTO `gudang` (`gudang_id`, `lokasi`, `kapasitas`, `manajer`) VALUES
(0, 'lokasi', 0, 'manajer'),
(1, 'Yogyakarta', 3821, 'Dewi Lestari'),
(2, 'Yogyakarta', 1468, 'Adi Santoso'),
(3, 'Makassar', 3569, 'Dewi Lestari'),
(4, 'Malang', 2205, 'Fajar Pratama'),
(5, 'Balikpapan', 3028, 'Eka Putra'),
(6, 'Balikpapan', 4076, 'Budi Wijaya'),
(7, 'Palembang', 1334, 'Citra Dewi'),
(8, 'Surabaya', 4519, 'Fajar Pratama'),
(9, 'Yogyakarta', 2142, 'Intan Permata'),
(10, 'Balikpapan', 3743, 'Budi Wijaya'),
(11, 'Jakarta', 3109, 'Fajar Pratama'),
(12, 'Semarang', 1524, 'Adi Santoso'),
(13, 'Malang', 774, 'Eka Putra'),
(14, 'Makassar', 2732, 'Intan Permata'),
(15, 'Balikpapan', 2713, 'Budi Wijaya'),
(16, 'Surabaya', 3573, 'Fajar Pratama'),
(17, 'Makassar', 3544, 'Dewi Lestari'),
(18, 'Jakarta', 4244, 'Adi Santoso'),
(19, 'Bandung', 2822, 'Hendra Gunawan'),
(20, 'Jakarta', 4737, 'Fajar Pratama'),
(21, 'Jakarta', 3861, 'Eka Putra'),
(22, 'Surabaya', 1254, 'Citra Dewi'),
(23, 'Semarang', 2268, 'Adi Santoso'),
(24, 'Palembang', 2020, 'Eka Putra'),
(25, 'Surabaya', 4873, 'Budi Wijaya'),
(26, 'Yogyakarta', 795, 'Adi Santoso'),
(27, 'Jakarta', 1533, 'Budi Wijaya'),
(28, 'Balikpapan', 2992, 'Intan Permata'),
(29, 'Balikpapan', 4863, 'Eka Putra'),
(30, 'Jakarta', 2244, 'Eka Putra'),
(31, 'Medan', 2668, 'Citra Dewi'),
(32, 'Balikpapan', 1702, 'Budi Wijaya'),
(33, 'Medan', 742, 'Eka Putra'),
(34, 'Surabaya', 2310, 'Citra Dewi'),
(35, 'Balikpapan', 983, 'Eka Putra'),
(36, 'Surabaya', 3024, 'Hendra Gunawan'),
(37, 'Malang', 1776, 'Adi Santoso'),
(38, 'Makassar', 863, 'Intan Permata'),
(39, 'Semarang', 4103, 'Eka Putra'),
(40, 'Malang', 2574, 'Citra Dewi'),
(41, 'Makassar', 989, 'Budi Wijaya'),
(42, 'Malang', 3092, 'Hendra Gunawan'),
(43, 'Semarang', 2748, 'Intan Permata'),
(44, 'Semarang', 1586, 'Budi Wijaya'),
(45, 'Semarang', 4628, 'Fajar Pratama'),
(46, 'Palembang', 3099, 'Adi Santoso'),
(47, 'Balikpapan', 844, 'Budi Wijaya'),
(48, 'Makassar', 3879, 'Gita Sari'),
(49, 'Malang', 4613, 'Dewi Lestari'),
(50, 'Balikpapan', 1523, 'Joko Susilo'),
(51, 'Jakarta', 1228, 'Eka Putra'),
(52, 'Balikpapan', 2782, 'Intan Permata'),
(53, 'Makassar', 3770, 'Hendra Gunawan'),
(54, 'Medan', 4809, 'Budi Wijaya'),
(55, 'Yogyakarta', 717, 'Citra Dewi'),
(56, 'Malang', 2028, 'Joko Susilo'),
(57, 'Semarang', 4169, 'Adi Santoso'),
(58, 'Yogyakarta', 2209, 'Hendra Gunawan'),
(59, 'Surabaya', 1686, 'Hendra Gunawan'),
(60, 'Palembang', 1691, 'Joko Susilo'),
(61, 'Surabaya', 2793, 'Hendra Gunawan'),
(62, 'Makassar', 2642, 'Joko Susilo'),
(63, 'Balikpapan', 1232, 'Citra Dewi'),
(64, 'Palembang', 2337, 'Eka Putra'),
(65, 'Yogyakarta', 3837, 'Dewi Lestari'),
(66, 'Yogyakarta', 2873, 'Gita Sari'),
(67, 'Medan', 4492, 'Eka Putra'),
(68, 'Bandung', 4895, 'Hendra Gunawan'),
(69, 'Balikpapan', 4358, 'Adi Santoso'),
(70, 'Balikpapan', 2473, 'Adi Santoso'),
(71, 'Medan', 4878, 'Dewi Lestari'),
(72, 'Makassar', 777, 'Eka Putra'),
(73, 'Balikpapan', 1159, 'Gita Sari'),
(74, 'Balikpapan', 1267, 'Hendra Gunawan'),
(75, 'Jakarta', 2096, 'Intan Permata'),
(76, 'Malang', 4088, 'Fajar Pratama'),
(77, 'Semarang', 4721, 'Fajar Pratama'),
(78, 'Jakarta', 3095, 'Fajar Pratama'),
(79, 'Semarang', 3153, 'Fajar Pratama'),
(80, 'Surabaya', 4571, 'Joko Susilo'),
(81, 'Palembang', 1172, 'Budi Wijaya'),
(82, 'Balikpapan', 4279, 'Hendra Gunawan'),
(83, 'Malang', 1986, 'Fajar Pratama'),
(84, 'Palembang', 3392, 'Budi Wijaya'),
(85, 'Makassar', 4471, 'Gita Sari'),
(86, 'Yogyakarta', 4971, 'Adi Santoso'),
(87, 'Bandung', 1562, 'Citra Dewi'),
(88, 'Bandung', 1297, 'Fajar Pratama'),
(89, 'Balikpapan', 1426, 'Eka Putra'),
(90, 'Balikpapan', 4183, 'Budi Wijaya'),
(91, 'Bandung', 610, 'Fajar Pratama'),
(92, 'Bandung', 696, 'Budi Wijaya'),
(93, 'Medan', 805, 'Eka Putra'),
(94, 'Makassar', 2037, 'Citra Dewi'),
(95, 'Palembang', 2731, 'Budi Wijaya'),
(96, 'Medan', 3661, 'Dewi Lestari'),
(97, 'Makassar', 996, 'Hendra Gunawan'),
(98, 'Bandung', 4690, 'Adi Santoso'),
(99, 'Surabaya', 3608, 'Gita Sari'),
(100, 'Makassar', 1498, 'Eka Putra');

-- --------------------------------------------------------

--
-- Struktur dari tabel `jenis_produk`
--

CREATE TABLE `jenis_produk` (
  `id_jenis_produk` int(11) NOT NULL,
  `kategori` varchar(50) DEFAULT NULL,
  `deskripsi` text DEFAULT NULL,
  `diskon` decimal(5,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `jenis_produk`
--

INSERT INTO `jenis_produk` (`id_jenis_produk`, `kategori`, `deskripsi`, `diskon`) VALUES
(0, 'kategori', 'deskripsi', 0.00),
(1, 'guy', 'Wrong imagine born despite test cause.', 0.10),
(2, 'tough', 'You side travel eight behind add.', 0.07),
(3, 'smile', 'Nature amount may thought sure.', 0.11),
(4, 'form', 'Administration perform official wonder same mind.', 0.29),
(5, 'not', 'Since something not our series fear daughter.', 0.11),
(6, 'national', 'Campaign often face call almost network.', 0.28),
(7, 'simply', 'Coach worry nice.', 0.16),
(8, 'whom', 'Ok blue address fill to without.', 0.06),
(9, 'trouble', 'Experience experience likely leader scientist.', 0.18),
(10, 'society', 'Dog strategy huge small commercial defense.', 0.17),
(11, 'force', 'Six officer nice nor.', 0.12),
(12, 'future', 'Music turn hand game need say newspaper outside.', 0.50),
(13, 'exactly', 'Manager out agreement sport crime tell officer.', 0.34),
(14, 'risk', 'Exist cost live direction court say them.', 0.02),
(15, 'far', 'Wife else stop religious.', 0.25),
(16, 'this', 'Fly among staff individual seek.', 0.16),
(17, 'article', 'Soldier score bag they.', 0.47),
(18, 'plan', 'Development real bag market perhaps current course.', 0.04),
(19, 'claim', 'Away hour not money community.', 0.38),
(20, 'small', 'Oil why soon reason small.', 0.44),
(21, 'movement', 'Term arm office mean forget.', 0.04),
(22, 'in', 'Leave subject do Mr seat describe another program.', 0.20),
(23, 'during', 'Step I reveal develop.', 0.37),
(24, 'soldier', 'Security even drive a.', 0.40),
(25, 'become', 'Spring form it four.', 0.12),
(26, 'themselves', 'Project determine nature suggest at upon audience.', 0.48),
(27, 'realize', 'General significant rest deal character scientist fly.', 0.05),
(28, 'thousand', 'Cut area sell kid sell almost mouth relationship.', 0.26),
(29, 'lawyer', 'Rock dinner win often approach tree sit.', 0.22),
(30, 'daughter', 'Add ability skill media stock which move low.', 0.36),
(31, 'imagine', 'Development just single back.', 0.28),
(32, 'claim', 'Recent another poor charge.', 0.39),
(33, 'beautiful', 'Movie radio class agreement.', 0.04),
(34, 'result', 'Remember here we which.', 0.07),
(35, 'thus', 'Baby recent opportunity argue like money church.', 0.00),
(36, 'art', 'Final feel rise.', 0.19),
(37, 'country', 'Spring rock able until stand guess perform.', 0.14),
(38, 'since', 'Training past series growth.', 0.14),
(39, 'which', 'Center bit write.', 0.05),
(40, 'remember', 'Create would with ever.', 0.43),
(41, 'network', 'Their approach authority true hospital list wide fly.', 0.16),
(42, 'explain', 'Provide resource begin evidence.', 0.15),
(43, 'beyond', 'Debate mean allow guy within beyond.', 0.15),
(44, 'standard', 'Form center fine teacher.', 0.38),
(45, 'line', 'Site no media painting third dinner ask.', 0.22),
(46, 'change', 'Him thank certain none north consider wall break.', 0.23),
(47, 'cultural', 'Door language never protect sister camera still.', 0.49),
(48, 'history', 'Fall town surface present.', 0.25),
(49, 'late', 'Common together behavior interest.', 0.28),
(50, 'free', 'Education start sort offer.', 0.15),
(51, 'certain', 'Blood everything woman.', 0.10),
(52, 'star', 'Put space case try.', 0.08),
(53, 'church', 'Level art good quickly traditional sister relationship investment.', 0.15),
(54, 'indicate', 'Political family wife fine born every.', 0.13),
(55, 'serious', 'Evening case buy energy wear smile own.', 0.12),
(56, 'theory', 'Human actually big many vote.', 0.44),
(57, 'citizen', 'Whole control standard full join stage.', 0.20),
(58, 'writer', 'Drive politics discuss.', 0.05),
(59, 'many', 'Couple teach while company scientist.', 0.37),
(60, 'level', 'Up back left necessary fact star.', 0.38),
(61, 'note', 'Sea PM front ahead memory.', 0.08),
(62, 'step', 'Mother research wife together small quickly region.', 0.20),
(63, 'wall', 'Break agree most happen run up door least.', 0.04),
(64, 'figure', 'Hear note take than culture Republican avoid.', 0.17),
(65, 'it', 'Democratic institution tough thousand hotel itself.', 0.40),
(66, 'stop', 'Their clear particular clear necessary easy wide.', 0.24),
(67, 'star', 'Issue serious together audience.', 0.15),
(68, 'quickly', 'Land wish fight street audience surface.', 0.21),
(69, 'meet', 'Add glass child.', 0.25),
(70, 'dog', 'Here dark decision ground base term.', 0.28),
(71, 'source', 'Month save toward type create order member.', 0.15),
(72, 'bed', 'Military all possible because every special pass offer.', 0.24),
(73, 'safe', 'Than computer if party risk since middle.', 0.44),
(74, 'past', 'Campaign Republican including.', 0.48),
(75, 'degree', 'Smile ready life lot anything because improve.', 0.48),
(76, 'once', 'Add admit son bar.', 0.10),
(77, 'network', 'Later weight he.', 0.36),
(78, 'movement', 'Daughter field student fill indeed interesting something.', 0.25),
(79, 'film', 'Raise offer different president health between.', 0.42),
(80, 'our', 'Price yourself avoid begin religious.', 0.20),
(81, 'chair', 'Wait today simple note discover.', 0.16),
(82, 'hotel', 'Gas seek report them.', 0.43),
(83, 'window', 'Senior view partner bad.', 0.29),
(84, 'board', 'Cause society eight next let radio science member.', 0.06),
(85, 'land', 'Knowledge purpose none director paper little contain.', 0.15),
(86, 'Congress', 'Young line condition rest song staff after modern.', 0.46),
(87, 'possible', 'Someone drop career they majority organization.', 0.08),
(88, 'help', 'Mention study station.', 0.37),
(89, 'art', 'Street break next enough.', 0.38),
(90, 'life', 'Certain participant unit get more.', 0.39),
(91, 'house', 'Impact common big behind soon happen positive great.', 0.22),
(92, 'work', 'Drug less himself sort that.', 0.34),
(93, 'minute', 'Carry stock increase teacher identify debate throughout.', 0.04),
(94, 'ball', 'Authority will third star key.', 0.05),
(95, 'a', 'High your life hotel politics true actually.', 0.01),
(96, 'main', 'Argue energy go change language.', 0.11),
(97, 'statement', 'Determine bring remain travel key budget class.', 0.20),
(98, 'believe', 'Manage campaign smile speak popular pattern door.', 0.38),
(99, 'international', 'Here lay her enough product.', 0.00),
(100, 'prevent', 'Appear blood one language account tonight already popular.', 0.41),
(101, 'your', 'Purpose in six decade stop message.', 0.07),
(102, 'collection', 'Respond easy long.', 0.33),
(103, 'herself', 'Line real few area light.', 0.01),
(104, 'happen', 'Present after he animal decade able because message.', 0.48),
(105, 'price', 'Fast it discussion charge available.', 0.39),
(106, 'race', 'Order model Republican owner reality form.', 0.07),
(107, 'everybody', 'American send attack.', 0.28),
(108, 'media', 'Pass dog place role conference single.', 0.07),
(109, 'note', 'Others source trouble size hold remember pass.', 0.22),
(110, 'group', 'Wind order either effect.', 0.30),
(111, 'miss', 'Very conference century cost remember.', 0.41),
(112, 'how', 'Team science those.', 0.04),
(113, 'commercial', 'Security medical short too debate expert.', 0.30),
(114, 'senior', 'Arrive or piece society industry number strategy fly.', 0.00),
(115, 'realize', 'Send trip least positive.', 0.32),
(116, 'choose', 'Community cultural throw position professor return.', 0.37),
(117, 'else', 'Personal anything base about growth cell office.', 0.44),
(118, 'care', 'Including now good compare dream international would.', 0.21),
(119, 'fill', 'Level beyond market leave message.', 0.23),
(120, 'hair', 'Certainly choose him in phone society teacher view.', 0.37),
(121, 'young', 'Ever whether exist instead hundred ability.', 0.27),
(122, 'case', 'Focus call face through race mouth.', 0.30),
(123, 'already', 'We which watch exactly.', 0.20),
(124, 'learn', 'Score you people TV notice compare assume.', 0.13),
(125, 'key', 'Wait yes people article only drive.', 0.49),
(126, 'future', 'Cut leave everything.', 0.12),
(127, 'song', 'People successful space carry program law prove treatment.', 0.25),
(128, 'fund', 'Order side stay next send once truth.', 0.34),
(129, 'most', 'Support senior rule even apply too bar.', 0.46),
(130, 'water', 'Wish trade pretty.', 0.24),
(131, 'become', 'Learn student throw allow enjoy child.', 0.46),
(132, 'environment', 'Series quite trial individual.', 0.39),
(133, 'real', 'Despite structure specific defense standard dog take.', 0.15),
(134, 'smile', 'Indeed newspaper perform agreement over eat.', 0.37),
(135, 'white', 'Claim page group city international similar effort.', 0.47),
(136, 'eight', 'Large look protect key.', 0.03),
(137, 'station', 'Store others decision because until explain.', 0.24),
(138, 'sound', 'Alone shoulder tell actually effect worker.', 0.18),
(139, 'into', 'Meeting health manage low knowledge capital ok.', 0.17),
(140, 'American', 'View plan hot brother successful response.', 0.49),
(141, 'throughout', 'Free end social great apply couple maintain attention.', 0.30),
(142, 'sea', 'Enter never brother.', 0.27),
(143, 'court', 'Dinner stay rather shoulder general yet candidate person.', 0.42),
(144, 'culture', 'Win natural style relationship adult bill.', 0.11),
(145, 'sign', 'Read hair summer around later why lawyer.', 0.25),
(146, 'main', 'What guy they today example interview foreign.', 0.04),
(147, 'manage', 'Pattern just seat role fast in dinner.', 0.23),
(148, 'boy', 'Military program issue forget particularly yes.', 0.42),
(149, 'couple', 'Within interesting card between agreement commercial.', 0.16),
(150, 'feeling', 'Occur feel tend mouth somebody.', 0.44),
(151, 'year', 'How future dream approach upon.', 0.33),
(152, 'bag', 'On back with article.', 0.47),
(153, 'TV', 'Smile respond degree talk hair friend.', 0.33),
(154, 'pressure', 'Audience very make key interview low last hope.', 0.33),
(155, 'understand', 'Method space rock environmental discover throughout bag.', 0.26),
(156, 'significant', 'Actually most police former produce kitchen quite foot.', 0.31),
(157, 'ahead', 'Standard foot mind economic community.', 0.11),
(158, 'sister', 'Response girl positive similar each try.', 0.09),
(159, 'finish', 'Chance forward wide myself your thus news.', 0.09),
(160, 'certain', 'Alone indicate service activity sport network.', 0.33);

-- --------------------------------------------------------

--
-- Struktur dari tabel `karyawan`
--

CREATE TABLE `karyawan` (
  `karyawan_id` int(11) NOT NULL,
  `nama` varchar(100) DEFAULT NULL,
  `jabatan` varchar(50) DEFAULT NULL,
  `nomor_hp` varchar(20) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `karyawan`
--

INSERT INTO `karyawan` (`karyawan_id`, `nama`, `jabatan`, `nomor_hp`, `email`) VALUES
(0, 'nama', 'jabatan', 'nomor_hp', 'email'),
(1, 'Dewi Kristanto', 'Barista', '086098470071', 'dewi.kristanto@cafekita.com'),
(2, 'Hendra Mahendra', 'Barista', '084629999127', 'hendra.mahendra@cafekita.com'),
(3, 'Rina Kristanto', 'Supervisor', '080044932469', 'rina.kristanto@cafekita.com'),
(4, 'Umi Ningsih', 'Kasir', '081574317319', 'umi.ningsih@cafekita.com'),
(5, 'Hendra Mahendra', 'Staf Kebersihan', '080528680520', 'hendra.mahendra@cafekita.com'),
(6, 'Hendra Gunawan', 'Staf Kebersihan', '080085596452', 'hendra.gunawan@cafekita.com'),
(7, 'Budi Saputra', 'Staf Kebersihan', '083418022416', 'budi.saputra@cafekita.com'),
(8, 'Umi Hadi', 'Chef', '081423494066', 'umi.hadi@cafekita.com'),
(9, 'Joko Kristanto', 'Kasir', '089308897486', 'joko.kristanto@cafekita.com'),
(10, 'Intan Santoso', 'Supervisor', '083402211717', 'intan.santoso@cafekita.com'),
(11, 'Tito Ningsih', 'Staf Kebersihan', '088091908779', 'tito.ningsih@cafekita.com'),
(12, 'Eka Saputra', 'Barista', '084217542212', 'eka.saputra@cafekita.com'),
(13, 'Dewi Wijaya', 'Kasir', '084901238554', 'dewi.wijaya@cafekita.com'),
(14, 'Umi Kristanto', 'Supervisor', '089695110805', 'umi.kristanto@cafekita.com'),
(15, 'Joko Ningsih', 'Chef', '080373732662', 'joko.ningsih@cafekita.com'),
(16, 'Putu Gunawan', 'Manager', '083751673979', 'putu.gunawan@cafekita.com'),
(17, 'Hendra Sari', 'Pelayan', '085400153170', 'hendra.sari@cafekita.com'),
(18, 'Lina Permata', 'Chef', '084499679607', 'lina.permata@cafekita.com'),
(19, 'Putu Wahyudi', 'Barista', '083933351002', 'putu.wahyudi@cafekita.com'),
(20, 'Oka Kristanto', 'Kasir', '088918679618', 'oka.kristanto@cafekita.com'),
(21, 'Tito Kristanto', 'Supervisor', '089186151888', 'tito.kristanto@cafekita.com'),
(22, 'Umi Ningsih', 'Staf Gudang', '080873470631', 'umi.ningsih@cafekita.com'),
(23, 'Fajar Wijaya', 'Manager', '083408385276', 'fajar.wijaya@cafekita.com'),
(24, 'Nina Kristanto', 'Kasir', '086765160257', 'nina.kristanto@cafekita.com'),
(25, 'Fajar Kristanto', 'Kasir', '084439081094', 'fajar.kristanto@cafekita.com'),
(26, 'Oka Pratama', 'Chef', '089954192036', 'oka.pratama@cafekita.com'),
(27, 'Nina Lestari', 'Chef', '087319589222', 'nina.lestari@cafekita.com'),
(28, 'Citra Wahyudi', 'Barista', '085016109156', 'citra.wahyudi@cafekita.com'),
(29, 'Joko Nur', 'Manager', '086164106459', 'joko.nur@cafekita.com'),
(30, 'Tito Sari', 'Staf Kebersihan', '082356723175', 'tito.sari@cafekita.com'),
(31, 'Gita Mahendra', 'Chef', '086790516003', 'gita.mahendra@cafekita.com'),
(32, 'Nina Mahendra', 'Barista', '081992041356', 'nina.mahendra@cafekita.com'),
(33, 'Oka Rahma', 'Barista', '082622587238', 'oka.rahma@cafekita.com'),
(34, 'Eka Saputra', 'Manager', '081806411742', 'eka.saputra@cafekita.com'),
(35, 'Lina Fadhil', 'Chef', '082037288093', 'lina.fadhil@cafekita.com'),
(36, 'Kiki Pratama', 'Manager', '083971874155', 'kiki.pratama@cafekita.com'),
(37, 'Putu Yuliani', 'Pelayan', '086160735317', 'putu.yuliani@cafekita.com'),
(38, 'Adi Rahma', 'Staf Gudang', '087491219161', 'adi.rahma@cafekita.com'),
(39, 'Intan Fadhil', 'Kasir', '087158690710', 'intan.fadhil@cafekita.com'),
(40, 'Citra Susilo', 'Barista', '088591402603', 'citra.susilo@cafekita.com'),
(41, 'Tito Nur', 'Supervisor', '086115465601', 'tito.nur@cafekita.com'),
(42, 'Fajar Kristanto', 'Chef', '083206969121', 'fajar.kristanto@cafekita.com'),
(43, 'Tito Nur', 'Staf Pemasaran', '084789382980', 'tito.nur@cafekita.com'),
(44, 'Kiki Wahyudi', 'Manager', '083946985019', 'kiki.wahyudi@cafekita.com'),
(45, 'Oka Saputra', 'Kasir', '080353234541', 'oka.saputra@cafekita.com'),
(46, 'Maya Yuliani', 'Staf Pemasaran', '080906434501', 'maya.yuliani@cafekita.com'),
(47, 'Tito Santoso', 'Staf Pemasaran', '089638475666', 'tito.santoso@cafekita.com'),
(48, 'Fajar Rahma', 'Chef', '080676397886', 'fajar.rahma@cafekita.com'),
(49, 'Nina Wijaya', 'Staf Pemasaran', '087940468076', 'nina.wijaya@cafekita.com'),
(50, 'Fajar Hadi', 'Manager', '083223320460', 'fajar.hadi@cafekita.com'),
(51, 'Dewi Yuliani', 'Supervisor', '087450892784', 'dewi.yuliani@cafekita.com'),
(52, 'Hendra Rahma', 'Staf Gudang', '084685399253', 'hendra.rahma@cafekita.com'),
(53, 'Hendra Rahma', 'Kasir', '084083915437', 'hendra.rahma@cafekita.com'),
(54, 'Kiki Gunawan', 'Manager', '081246079395', 'kiki.gunawan@cafekita.com'),
(55, 'Eka Kristanto', 'Supervisor', '088235030665', 'eka.kristanto@cafekita.com'),
(56, 'Eka Pratama', 'Staf Gudang', '088033684235', 'eka.pratama@cafekita.com'),
(57, 'Nina Wijaya', 'Staf Kebersihan', '085000656724', 'nina.wijaya@cafekita.com'),
(58, 'Maya Yuliani', 'Staf Pemasaran', '084447073531', 'maya.yuliani@cafekita.com'),
(59, 'Maya Fadhil', 'Supervisor', '082414995019', 'maya.fadhil@cafekita.com'),
(60, 'Gita Pratama', 'Staf Gudang', '089612358328', 'gita.pratama@cafekita.com'),
(61, 'Hendra Saputra', 'Staf Gudang', '088345607087', 'hendra.saputra@cafekita.com'),
(62, 'Tito Santoso', 'Barista', '082808734285', 'tito.santoso@cafekita.com'),
(63, 'Gita Mahendra', 'Staf Pemasaran', '088110444369', 'gita.mahendra@cafekita.com'),
(64, 'Kiki Susilo', 'Staf Pemasaran', '086019484184', 'kiki.susilo@cafekita.com'),
(65, 'Tito Pratama', 'Pelayan', '082065846953', 'tito.pratama@cafekita.com'),
(66, 'Intan Santoso', 'Staf Gudang', '083768169264', 'intan.santoso@cafekita.com'),
(67, 'Oka Yuliani', 'Barista', '081476972348', 'oka.yuliani@cafekita.com'),
(68, 'Sari Nur', 'Barista', '080838915461', 'sari.nur@cafekita.com'),
(69, 'Eka Yuliani', 'Staf Kebersihan', '081111821600', 'eka.yuliani@cafekita.com'),
(70, 'Rina Rahma', 'Pelayan', '089810011291', 'rina.rahma@cafekita.com'),
(71, 'Umi Santoso', 'Staf Pemasaran', '081243706103', 'umi.santoso@cafekita.com'),
(72, 'Budi Santoso', 'Manager', '083179427017', 'budi.santoso@cafekita.com'),
(73, 'Hendra Dewi', 'Barista', '085214842928', 'hendra.dewi@cafekita.com'),
(74, 'Putu Lestari', 'Barista', '085589558583', 'putu.lestari@cafekita.com'),
(75, 'Adi Wahyudi', 'Supervisor', '086779637791', 'adi.wahyudi@cafekita.com'),
(76, 'Sari Ningsih', 'Pelayan', '084528571607', 'sari.ningsih@cafekita.com'),
(77, 'Kiki Yuliani', 'Kasir', '082509291718', 'kiki.yuliani@cafekita.com'),
(78, 'Gita Gunawan', 'Barista', '085716835336', 'gita.gunawan@cafekita.com'),
(79, 'Budi Yuliani', 'Barista', '080000114545', 'budi.yuliani@cafekita.com'),
(80, 'Dewi Wijaya', 'Pelayan', '082051337086', 'dewi.wijaya@cafekita.com'),
(81, 'Gita Gunawan', 'Barista', '080304511631', 'gita.gunawan@cafekita.com'),
(82, 'Hendra Mahendra', 'Kasir', '085047254695', 'hendra.mahendra@cafekita.com'),
(83, 'Fajar Lestari', 'Staf Kebersihan', '087348664005', 'fajar.lestari@cafekita.com'),
(84, 'Putu Nur', 'Manager', '084821268333', 'putu.nur@cafekita.com'),
(85, 'Rina Kristanto', 'Barista', '089494383134', 'rina.kristanto@cafekita.com'),
(86, 'Dewi Rahma', 'Staf Kebersihan', '086115493159', 'dewi.rahma@cafekita.com'),
(87, 'Sari Santoso', 'Supervisor', '089177129680', 'sari.santoso@cafekita.com'),
(88, 'Budi Mahendra', 'Staf Gudang', '086745023918', 'budi.mahendra@cafekita.com'),
(89, 'Intan Putra', 'Staf Kebersihan', '088253654316', 'intan.putra@cafekita.com'),
(90, 'Citra Permata', 'Supervisor', '082246636277', 'citra.permata@cafekita.com'),
(91, 'Umi Saputra', 'Barista', '085916443398', 'umi.saputra@cafekita.com'),
(92, 'Adi Rahma', 'Pelayan', '085078575793', 'adi.rahma@cafekita.com'),
(93, 'Intan Lestari', 'Staf Gudang', '085712104597', 'intan.lestari@cafekita.com'),
(94, 'Nina Sari', 'Supervisor', '081759048174', 'nina.sari@cafekita.com'),
(95, 'Dewi Wijaya', 'Staf Kebersihan', '086774795631', 'dewi.wijaya@cafekita.com'),
(96, 'Gita Fadhil', 'Pelayan', '089775612823', 'gita.fadhil@cafekita.com'),
(97, 'Joko Saputra', 'Staf Gudang', '083085940665', 'joko.saputra@cafekita.com'),
(98, 'Sari Permata', 'Barista', '089733433957', 'sari.permata@cafekita.com'),
(99, 'Adi Hadi', 'Staf Gudang', '083282924222', 'adi.hadi@cafekita.com'),
(100, 'Citra Kristanto', 'Pelayan', '087171088752', 'citra.kristanto@cafekita.com');

-- --------------------------------------------------------

--
-- Struktur dari tabel `minuman`
--

CREATE TABLE `minuman` (
  `jenis_minuman` varchar(100) NOT NULL,
  `jumlah` int(11) DEFAULT NULL,
  `tanggal_kadaluwarsa` date DEFAULT NULL,
  `id_jenis_produk` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `minuman`
--

INSERT INTO `minuman` (`jenis_minuman`, `jumlah`, `tanggal_kadaluwarsa`, `id_jenis_produk`) VALUES
('Air Mineral', 80, '2025-07-10', 29),
('Cappuccino', 6, '2026-01-12', 24),
('Espresso Arabica', 76, '2025-11-20', 20),
('jenis_minuman', 0, '0000-00-00', 0),
('Jus Jeruk Segar', 41, '2026-03-12', 19),
('Kopi Tubruk', 85, '2026-04-15', 25),
('Latte Vanila', 70, '2026-03-04', 29),
('Matcha Latte', 36, '2025-10-24', 57),
('Mocha Coklat', 39, '2025-10-12', 66),
('Smoothie Berry', 86, '2025-06-06', 72),
('Teh Hijau', 16, '2025-12-31', 79);

-- --------------------------------------------------------

--
-- Struktur dari tabel `non_tunai`
--

CREATE TABLE `non_tunai` (
  `pembayaran_id` int(11) NOT NULL,
  `no_rekening` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `non_tunai`
--

INSERT INTO `non_tunai` (`pembayaran_id`, `no_rekening`) VALUES
(1, '9340919141824259'),
(2, '6255145022359527'),
(3, '8563512369980374'),
(4, '8124155619058912'),
(5, '2954163149846296'),
(6, '2527511754288780'),
(7, '8920760751859637'),
(8, '7538735938077035'),
(9, '3234908632168890'),
(10, '7601859859112995'),
(11, '6404262192022507'),
(12, '6609548242394057'),
(13, '6117168159224871'),
(14, '5346456859703462'),
(15, '7605888615217270'),
(16, '5583479261233210'),
(17, '5434046182435455'),
(18, '6773322945156731'),
(19, '7432794990940044'),
(20, '3494670575211167'),
(21, '6431096740962312'),
(22, '0719683132624848'),
(23, '0140195925846799'),
(24, '1451301280062595'),
(25, '5415930052788155'),
(26, '1250579095393413'),
(27, '1702726298371899'),
(28, '7156351913634456'),
(29, '0914499220162000'),
(30, '4953253774212862'),
(31, '8764176560491905'),
(32, '5048707295143353'),
(33, '2362045431547783'),
(34, '9763554025501981'),
(35, '8235939777069792'),
(36, '2568899458613293'),
(37, '1611087567196048'),
(38, '7502960606629324'),
(39, '4333874317810750'),
(40, '5881822721957293'),
(41, '8379795721860965'),
(42, '8763707939832978'),
(43, '3773074145839312'),
(44, '7543939234519509'),
(45, '7909893588440528'),
(46, '8325305240764187'),
(47, '7959979557081882'),
(48, '4048725923514502'),
(49, '7780982429569837'),
(50, '0070255278753965'),
(51, '4202632609566986'),
(52, '4401438372269924'),
(53, '6437776801878166'),
(54, '1154044450660066'),
(55, '9275965829167416'),
(56, '4902858366025246'),
(57, '3693803958875891'),
(58, '0189706912481213'),
(59, '4816807382598662'),
(60, '9365884568610408'),
(61, '3329244047531626'),
(62, '6187565978544678'),
(63, '3490676687200545'),
(64, '4093407423660009'),
(65, '9651579246664343'),
(66, '3997366584537565'),
(67, '1959423178804314'),
(68, '5914544648314618'),
(69, '8276662168716470'),
(70, '8048000573595826'),
(71, '5156265310471268'),
(72, '9157049618695444'),
(73, '1148507414964322'),
(74, '8623963519742924'),
(75, '3685692047780604'),
(76, '7964973527632061'),
(77, '5580735957253306'),
(78, '0033353506005293'),
(79, '1575996731787691'),
(80, '8626427830207833'),
(81, '8281346393095110'),
(82, '1094235417301795'),
(83, '9478115065268657'),
(84, '8682864592963514'),
(85, '7324511362552880'),
(86, '6755675331146728'),
(87, '9797025223996822'),
(88, '5555377750021005'),
(89, '2757599014053061'),
(90, '5596267173183200'),
(91, '4785987456347745'),
(92, '9810133136832487'),
(93, '0163935325010157'),
(94, '3570066882770118'),
(95, '5438561442841866'),
(96, '2475008974357446'),
(97, '0670645245972337'),
(98, '4587096792196828'),
(99, '8482494640675191'),
(100, '3289184143552689');

-- --------------------------------------------------------

--
-- Struktur dari tabel `part_time`
--

CREATE TABLE `part_time` (
  `karyawan_id` int(11) NOT NULL,
  `jam_kerja` varchar(50) DEFAULT NULL,
  `tanggal_masuk` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `part_time`
--

INSERT INTO `part_time` (`karyawan_id`, `jam_kerja`, `tanggal_masuk`) VALUES
(0, 'jam_kerja', '0000-00-00'),
(1, '14:00-22:00', '2024-05-23'),
(2, '09:00-17:00', '2025-03-20'),
(3, '16:00-20:00', '2024-08-08'),
(4, '14:00-22:00', '2024-08-05'),
(5, '08:00-12:00', '2025-05-02'),
(6, '10:00-18:00', '2025-02-26'),
(7, '14:00-22:00', '2024-12-18'),
(8, '08:00-12:00', '2024-11-10'),
(9, '09:00-17:00', '2025-04-22'),
(10, '08:00-12:00', '2025-03-30'),
(11, '16:00-20:00', '2024-09-30'),
(12, '14:00-22:00', '2024-10-01'),
(13, '08:00-12:00', '2025-02-05'),
(14, '08:00-12:00', '2024-12-02'),
(15, '08:00-12:00', '2025-02-13'),
(16, '08:00-12:00', '2024-07-29'),
(17, '10:00-18:00', '2024-08-29'),
(18, '16:00-20:00', '2024-11-04'),
(19, '10:00-18:00', '2024-05-10'),
(20, '12:00-16:00', '2025-03-30'),
(21, '16:00-20:00', '2025-03-13'),
(22, '10:00-18:00', '2024-09-10'),
(23, '16:00-20:00', '2024-12-11'),
(24, '16:00-20:00', '2025-02-03'),
(25, '10:00-18:00', '2024-11-15'),
(26, '10:00-18:00', '2024-06-15'),
(27, '10:00-18:00', '2025-04-01'),
(28, '08:00-12:00', '2025-01-15'),
(29, '12:00-16:00', '2024-05-06'),
(30, '08:00-12:00', '2024-08-19'),
(31, '08:00-12:00', '2024-09-12'),
(32, '09:00-17:00', '2025-04-18'),
(33, '14:00-22:00', '2024-09-26'),
(34, '10:00-18:00', '2024-11-30'),
(35, '10:00-18:00', '2024-09-29'),
(36, '10:00-18:00', '2024-06-14'),
(37, '08:00-12:00', '2025-04-21'),
(38, '12:00-16:00', '2024-05-04'),
(39, '10:00-18:00', '2025-03-12'),
(40, '16:00-20:00', '2024-08-10'),
(41, '16:00-20:00', '2025-04-19'),
(42, '09:00-17:00', '2024-12-04'),
(43, '09:00-17:00', '2025-01-24'),
(44, '16:00-20:00', '2024-06-06'),
(45, '10:00-18:00', '2024-11-25'),
(46, '12:00-16:00', '2024-06-01'),
(47, '08:00-12:00', '2024-08-10'),
(48, '09:00-17:00', '2024-06-26'),
(49, '14:00-22:00', '2024-12-03'),
(50, '09:00-17:00', '2024-12-22'),
(51, '14:00-22:00', '2024-06-12'),
(52, '12:00-16:00', '2025-03-30'),
(53, '12:00-16:00', '2024-06-17'),
(54, '16:00-20:00', '2024-05-08'),
(55, '14:00-22:00', '2025-03-05'),
(56, '14:00-22:00', '2025-04-08'),
(57, '10:00-18:00', '2025-04-05'),
(58, '16:00-20:00', '2025-03-26'),
(59, '12:00-16:00', '2024-07-27'),
(60, '16:00-20:00', '2024-11-23'),
(61, '09:00-17:00', '2024-11-10'),
(62, '14:00-22:00', '2024-09-10'),
(63, '12:00-16:00', '2024-08-16'),
(64, '08:00-12:00', '2024-11-01'),
(65, '12:00-16:00', '2024-05-31'),
(66, '10:00-18:00', '2025-02-08'),
(67, '10:00-18:00', '2024-10-06'),
(68, '12:00-16:00', '2025-03-29'),
(69, '16:00-20:00', '2024-08-03'),
(70, '16:00-20:00', '2024-09-06'),
(71, '16:00-20:00', '2024-07-17'),
(72, '08:00-12:00', '2025-04-24'),
(73, '10:00-18:00', '2024-10-12'),
(74, '14:00-22:00', '2025-03-22'),
(75, '10:00-18:00', '2024-06-26'),
(76, '08:00-12:00', '2024-05-15'),
(77, '12:00-16:00', '2024-12-13'),
(78, '09:00-17:00', '2024-12-28'),
(79, '08:00-12:00', '2024-10-25'),
(80, '14:00-22:00', '2024-05-12'),
(81, '10:00-18:00', '2024-05-31'),
(82, '08:00-12:00', '2024-10-05'),
(83, '08:00-12:00', '2024-09-25'),
(84, '08:00-12:00', '2024-08-07'),
(85, '14:00-22:00', '2024-08-26'),
(86, '14:00-22:00', '2024-08-25'),
(87, '16:00-20:00', '2025-01-20'),
(88, '12:00-16:00', '2025-04-29'),
(89, '10:00-18:00', '2024-09-19'),
(90, '09:00-17:00', '2025-01-14'),
(91, '14:00-22:00', '2024-10-21'),
(92, '10:00-18:00', '2025-05-02'),
(93, '09:00-17:00', '2024-09-14'),
(94, '09:00-17:00', '2025-02-03'),
(95, '12:00-16:00', '2025-05-03'),
(96, '10:00-18:00', '2024-06-19'),
(97, '08:00-12:00', '2024-09-28'),
(98, '08:00-12:00', '2024-07-29'),
(99, '10:00-18:00', '2024-10-29'),
(100, '16:00-20:00', '2024-10-11');

-- --------------------------------------------------------

--
-- Struktur dari tabel `pelanggan`
--

CREATE TABLE `pelanggan` (
  `pelanggan_id` int(5) NOT NULL,
  `nama` varchar(25) NOT NULL,
  `nomor_hp` int(12) UNSIGNED NOT NULL,
  `email` varchar(20) NOT NULL,
  `alamat` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `pelanggan`
--

INSERT INTO `pelanggan` (`pelanggan_id`, `nama`, `nomor_hp`, `email`, `alamat`) VALUES
(1, 'Nicholas Uji', 4294960000, 'email', 'alamat'),
(2, 'Dewi Pratama', 4294967295, 'dewi.pratama@cafekit', 'Jl. Teuku Umar No.3, Makassar'),
(3, 'Eka Susilo', 4294967295, 'eka.susilo@cafekita.', 'Jl. Panglima Polim No.6, Denpasar'),
(4, 'Intan Pratama', 4294967295, 'intan.pratama@cafeki', 'Jl. Diponegoro No.2, Yogyakarta'),
(5, 'Fajar Sari', 4294967295, 'fajar.sari@cafekita.', 'Jl. Panglima Polim No.6, Denpasar'),
(6, 'Eka Sari', 4294967295, 'eka.sari@cafekita.co', 'Jl. Diponegoro No.8, Semarang'),
(7, 'Gita Susilo', 4294967295, 'gita.susilo@cafekita', 'Jl. Merdeka No.1, Jakarta'),
(8, 'Budi Wijaya', 4294967295, 'budi.wijaya@cafekita', 'Jl. Diponegoro No.2, Yogyakarta'),
(9, 'Andi Gunawan', 4294967295, 'andi.gunawan@cafekit', 'Jl. Pahlawan No.5, Surabaya'),
(10, 'Hendra Santoso', 4294967295, 'hendra.santoso@cafek', 'Jl. Sudirman No.10, Bandung'),
(11, 'Citra Gunawan', 4294967295, 'citra.gunawan@cafeki', 'Jl. Diponegoro No.2, Yogyakarta'),
(12, 'Eka Dewi', 4294967295, 'eka.dewi@cafekita.co', 'Jl. Panglima Polim No.6, Denpasar'),
(13, 'Budi Permata', 4294967295, 'budi.permata@cafekit', 'Jl. Merdeka No.1, Jakarta'),
(14, 'Citra Putra', 4294967295, 'citra.putra@cafekita', 'Jl. Diponegoro No.8, Semarang'),
(15, 'Andi Wijaya', 4294967295, 'andi.wijaya@cafekita', 'Jl. Diponegoro No.8, Semarang'),
(16, 'Dewi Dewi', 4294967295, 'dewi.dewi@cafekita.c', 'Jl. Sudirman No.10, Bandung'),
(17, 'Andi Permata', 4294967295, 'andi.permata@cafekit', 'Jl. Gajah Mada No.4, Palembang'),
(18, 'Dewi Wijaya', 4294967295, 'dewi.wijaya@cafekita', 'Jl. Diponegoro No.2, Yogyakarta'),
(19, 'Intan Gunawan', 4294967295, 'intan.gunawan@cafeki', 'Jl. Merdeka No.1, Jakarta'),
(20, 'Intan Permata', 4294967295, 'intan.permata@cafeki', 'Jl. Panglima Polim No.6, Denpasar'),
(21, 'Eka Putra', 4294967295, 'eka.putra@cafekita.c', 'Jl. Gajah Mada No.4, Palembang'),
(22, 'Hendra Susilo', 4294967295, 'hendra.susilo@cafeki', 'Jl. Gajah Mada No.4, Palembang'),
(23, 'Citra Dewi', 4294967295, 'citra.dewi@cafekita.', 'Jl. Diponegoro No.8, Semarang'),
(24, 'Fajar Wijaya', 4294967295, 'fajar.wijaya@cafekit', 'Jl. Teuku Umar No.3, Makassar'),
(25, 'Dewi Sari', 4294967295, 'dewi.sari@cafekita.c', 'Jl. K.H. Wahid Hasyim No.9, Malang'),
(26, 'Fajar Susilo', 4294967295, 'fajar.susilo@cafekit', 'Jl. Diponegoro No.2, Yogyakarta'),
(27, 'Fajar Gunawan', 4294967295, 'fajar.gunawan@cafeki', 'Jl. Gajah Mada No.4, Palembang'),
(28, 'Joko Santoso', 4294967295, 'joko.santoso@cafekit', 'Jl. Diponegoro No.8, Semarang'),
(29, 'Hendra Wijaya', 4294967295, 'hendra.wijaya@cafeki', 'Jl. K.H. Wahid Hasyim No.9, Malang'),
(30, 'Joko Dewi', 4294967295, 'joko.dewi@cafekita.c', 'Jl. Panglima Polim No.6, Denpasar'),
(31, 'Andi Susilo', 4294967295, 'andi.susilo@cafekita', 'Jl. K.H. Wahid Hasyim No.9, Malang'),
(32, 'Gita Pratama', 4294967295, 'gita.pratama@cafekit', 'Jl. Teuku Umar No.3, Makassar'),
(33, 'Gita Santoso', 4294967295, 'gita.santoso@cafekit', 'Jl. Merdeka No.1, Jakarta'),
(34, 'Andi Putra', 4294967295, 'andi.putra@cafekita.', 'Jl. Panglima Polim No.6, Denpasar'),
(35, 'Andi Putra', 4294967295, 'andi.putra@cafekita.', 'Jl. Diponegoro No.2, Yogyakarta'),
(36, 'Budi Susilo', 4294967295, 'budi.susilo@cafekita', 'Jl. Diponegoro No.8, Semarang'),
(37, 'Joko Permata', 4294967295, 'joko.permata@cafekit', 'Jl. K.H. Wahid Hasyim No.9, Malang'),
(38, 'Gita Permata', 4294967295, 'gita.permata@cafekit', 'Jl. Diponegoro No.8, Semarang'),
(39, 'Hendra Sari', 4294967295, 'hendra.sari@cafekita', 'Jl. Diponegoro No.2, Yogyakarta'),
(40, 'Hendra Permata', 4294967295, 'hendra.permata@cafek', 'Jl. Pahlawan No.5, Surabaya'),
(41, 'Hendra Putra', 4294967295, 'hendra.putra@cafekit', 'Jl. Gajah Mada No.4, Palembang'),
(42, 'Andi Susilo', 4294967295, 'andi.susilo@cafekita', 'Jl. Diponegoro No.2, Yogyakarta'),
(43, 'Gita Susilo', 4294967295, 'gita.susilo@cafekita', 'Jl. Diponegoro No.2, Yogyakarta'),
(44, 'Fajar Pratama', 4294967295, 'fajar.pratama@cafeki', 'Jl. Panglima Polim No.6, Denpasar'),
(45, 'Budi Permata', 4294967295, 'budi.permata@cafekit', 'Jl. Merdeka No.1, Jakarta'),
(46, 'Intan Pratama', 4294967295, 'intan.pratama@cafeki', 'Jl. Sudirman No.10, Bandung'),
(47, 'Fajar Lestari', 4294967295, 'fajar.lestari@cafeki', 'Jl. Diponegoro No.2, Yogyakarta'),
(48, 'Budi Permata', 4294967295, 'budi.permata@cafekit', 'Jl. K.H. Wahid Hasyim No.9, Malang'),
(49, 'Eka Sari', 4294967295, 'eka.sari@cafekita.co', 'Jl. Diponegoro No.2, Yogyakarta'),
(50, 'Joko Lestari', 4294967295, 'joko.lestari@cafekit', 'Jl. K.H. Wahid Hasyim No.9, Malang'),
(51, 'Citra Pratama', 4294967295, 'citra.pratama@cafeki', 'Jl. K.H. Wahid Hasyim No.9, Malang'),
(52, 'Andi Sari', 4294967295, 'andi.sari@cafekita.c', 'Jl. Imam Bonjol No.7, Medan'),
(53, 'Budi Gunawan', 4294967295, 'budi.gunawan@cafekit', 'Jl. Pahlawan No.5, Surabaya'),
(54, 'Joko Dewi', 4294967295, 'joko.dewi@cafekita.c', 'Jl. K.H. Wahid Hasyim No.9, Malang'),
(55, 'Citra Permata', 4294967295, 'citra.permata@cafeki', 'Jl. Imam Bonjol No.7, Medan'),
(56, 'Dewi Permata', 4294967295, 'dewi.permata@cafekit', 'Jl. Gajah Mada No.4, Palembang'),
(57, 'Fajar Sari', 4294967295, 'fajar.sari@cafekita.', 'Jl. Teuku Umar No.3, Makassar'),
(58, 'Andi Susilo', 4294967295, 'andi.susilo@cafekita', 'Jl. Merdeka No.1, Jakarta'),
(59, 'Citra Lestari', 4294967295, 'citra.lestari@cafeki', 'Jl. Teuku Umar No.3, Makassar'),
(60, 'Dewi Permata', 4294967295, 'dewi.permata@cafekit', 'Jl. Imam Bonjol No.7, Medan'),
(61, 'Joko Pratama', 4294967295, 'joko.pratama@cafekit', 'Jl. Diponegoro No.8, Semarang'),
(62, 'Hendra Pratama', 4294967295, 'hendra.pratama@cafek', 'Jl. Diponegoro No.2, Yogyakarta'),
(63, 'Gita Pratama', 4294967295, 'gita.pratama@cafekit', 'Jl. Gajah Mada No.4, Palembang'),
(64, 'Andi Sari', 4294967295, 'andi.sari@cafekita.c', 'Jl. Merdeka No.1, Jakarta'),
(65, 'Fajar Dewi', 4294967295, 'fajar.dewi@cafekita.', 'Jl. Sudirman No.10, Bandung'),
(66, 'Dewi Gunawan', 4294967295, 'dewi.gunawan@cafekit', 'Jl. Diponegoro No.2, Yogyakarta'),
(67, 'Dewi Susilo', 4294967295, 'dewi.susilo@cafekita', 'Jl. Sudirman No.10, Bandung'),
(68, 'Intan Santoso', 4294967295, 'intan.santoso@cafeki', 'Jl. Panglima Polim No.6, Denpasar'),
(69, 'Eka Wijaya', 4294967295, 'eka.wijaya@cafekita.', 'Jl. Pahlawan No.5, Surabaya'),
(70, 'Gita Putra', 4294967295, 'gita.putra@cafekita.', 'Jl. K.H. Wahid Hasyim No.9, Malang'),
(71, 'Eka Wijaya', 4294967295, 'eka.wijaya@cafekita.', 'Jl. Panglima Polim No.6, Denpasar'),
(72, 'Andi Wijaya', 4294967295, 'andi.wijaya@cafekita', 'Jl. Merdeka No.1, Jakarta'),
(73, 'Joko Pratama', 4294967295, 'joko.pratama@cafekit', 'Jl. Sudirman No.10, Bandung'),
(74, 'Eka Wijaya', 4294967295, 'eka.wijaya@cafekita.', 'Jl. Merdeka No.1, Jakarta'),
(75, 'Joko Lestari', 4294967295, 'joko.lestari@cafekit', 'Jl. Diponegoro No.8, Semarang'),
(76, 'Dewi Permata', 4294967295, 'dewi.permata@cafekit', 'Jl. Pahlawan No.5, Surabaya'),
(77, 'Fajar Permata', 4294967295, 'fajar.permata@cafeki', 'Jl. K.H. Wahid Hasyim No.9, Malang'),
(78, 'Citra Lestari', 4294967295, 'citra.lestari@cafeki', 'Jl. Panglima Polim No.6, Denpasar'),
(79, 'Budi Susilo', 4294967295, 'budi.susilo@cafekita', 'Jl. Teuku Umar No.3, Makassar'),
(80, 'Joko Gunawan', 4294967295, 'joko.gunawan@cafekit', 'Jl. Gajah Mada No.4, Palembang'),
(81, 'Hendra Dewi', 4294967295, 'hendra.dewi@cafekita', 'Jl. Teuku Umar No.3, Makassar'),
(82, 'Joko Gunawan', 4294967295, 'joko.gunawan@cafekit', 'Jl. Gajah Mada No.4, Palembang'),
(83, 'Hendra Sari', 4294967295, 'hendra.sari@cafekita', 'Jl. Diponegoro No.2, Yogyakarta'),
(84, 'Hendra Wijaya', 4294967295, 'hendra.wijaya@cafeki', 'Jl. Sudirman No.10, Bandung'),
(85, 'Fajar Wijaya', 4294967295, 'fajar.wijaya@cafekit', 'Jl. Merdeka No.1, Jakarta'),
(86, 'Citra Sari', 4294967295, 'citra.sari@cafekita.', 'Jl. Imam Bonjol No.7, Medan'),
(87, 'Hendra Pratama', 4294967295, 'hendra.pratama@cafek', 'Jl. K.H. Wahid Hasyim No.9, Malang'),
(88, 'Hendra Permata', 4294967295, 'hendra.permata@cafek', 'Jl. Diponegoro No.8, Semarang'),
(89, 'Andi Santoso', 4294967295, 'andi.santoso@cafekit', 'Jl. K.H. Wahid Hasyim No.9, Malang'),
(90, 'Gita Permata', 4294967295, 'gita.permata@cafekit', 'Jl. Pahlawan No.5, Surabaya'),
(91, 'Hendra Susilo', 4294967295, 'hendra.susilo@cafeki', 'Jl. Imam Bonjol No.7, Medan'),
(92, 'Gita Santoso', 4294967295, 'gita.santoso@cafekit', 'Jl. Panglima Polim No.6, Denpasar'),
(93, 'Hendra Putra', 4294967295, 'hendra.putra@cafekit', 'Jl. Diponegoro No.8, Semarang'),
(94, 'Andi Pratama', 4294967295, 'andi.pratama@cafekit', 'Jl. Teuku Umar No.3, Makassar'),
(95, 'Andi Lestari', 4294967295, 'andi.lestari@cafekit', 'Jl. Teuku Umar No.3, Makassar'),
(96, 'Citra Pratama', 4294967295, 'citra.pratama@cafeki', 'Jl. Diponegoro No.8, Semarang'),
(97, 'Dewi Sari', 4294967295, 'dewi.sari@cafekita.c', 'Jl. Sudirman No.10, Bandung'),
(98, 'Joko Santoso', 4294967295, 'joko.santoso@cafekit', 'Jl. Merdeka No.1, Jakarta'),
(99, 'Intan Wijaya', 4294967295, 'intan.wijaya@cafekit', 'Jl. Sudirman No.10, Bandung'),
(100, 'Eka Wijaya', 4294967295, 'eka.wijaya@cafekita.', 'Jl. Panglima Polim No.6, Denpasar');

-- --------------------------------------------------------

--
-- Struktur dari tabel `pembayaran`
--

CREATE TABLE `pembayaran` (
  `pembayaran_id` int(5) NOT NULL,
  `pesanan_id` int(5) NOT NULL,
  `tanggal_pembayaran` datetime NOT NULL,
  `metode_pembayaran` enum('tunai','non_tunai') DEFAULT NULL,
  `jumlah_bayar` int(20) NOT NULL,
  `nomor_refrensi` varchar(25) NOT NULL,
  `status_pembayaran` enum('Lunas','Belum Lunas') DEFAULT NULL,
  `karyawan_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `pembayaran`
--

INSERT INTO `pembayaran` (`pembayaran_id`, `pesanan_id`, `tanggal_pembayaran`, `metode_pembayaran`, `jumlah_bayar`, `nomor_refrensi`, `status_pembayaran`, `karyawan_id`) VALUES
(1, 48, '2025-07-16 21:48:09', 'tunai', 769363, 'REF3779789876', 'Lunas', 49),
(2, 8, '2025-01-02 05:55:23', 'non_tunai', 266250, 'REF6358875002', 'Lunas', 74),
(3, 79, '2025-02-08 19:35:32', 'tunai', 494489, 'REF7338301006', 'Belum Lunas', 94),
(4, 45, '2025-04-04 02:25:00', 'non_tunai', 540711, 'REF9307770543', 'Belum Lunas', 68),
(5, 92, '2025-01-20 12:14:19', 'tunai', 378673, 'REF9591232257', 'Belum Lunas', 76),
(6, 59, '2025-02-17 17:11:57', 'non_tunai', 722425, 'REF9345304867', 'Belum Lunas', 51),
(7, 40, '2025-05-12 13:31:09', 'tunai', 383196, 'REF8665657154', 'Lunas', 42),
(8, 30, '2025-10-11 01:34:56', 'tunai', 798670, 'REF6268241615', 'Belum Lunas', 50),
(9, 55, '2025-11-29 23:14:49', 'tunai', 776940, 'REF6597549681', 'Belum Lunas', 86),
(10, 31, '2025-12-30 15:31:40', 'tunai', 306755, 'REF7794759620', 'Belum Lunas', 36),
(11, 78, '2025-10-16 15:34:13', 'non_tunai', 676591, 'REF1849020762', 'Belum Lunas', 74),
(12, 14, '2025-12-08 08:34:09', 'non_tunai', 809630, 'REF0091153204', 'Lunas', 28),
(13, 29, '2025-01-09 23:51:19', 'non_tunai', 561524, 'REF9367102700', 'Lunas', 10),
(14, 47, '2025-06-27 06:01:15', 'non_tunai', 260773, 'REF0908451407', 'Lunas', 59),
(15, 51, '2025-06-26 17:15:27', 'tunai', 486094, 'REF3983710146', 'Belum Lunas', 62),
(16, 95, '2025-03-20 22:45:00', 'non_tunai', 56668, 'REF0101841685', 'Lunas', 13),
(17, 5, '2025-02-14 14:03:35', 'tunai', 657979, 'REF1285296257', 'Belum Lunas', 6),
(18, 6, '2025-11-24 07:39:09', 'tunai', 846522, 'REF6462687058', 'Belum Lunas', 74),
(19, 45, '2025-07-04 03:59:35', 'tunai', 477910, 'REF2561934035', 'Lunas', 85),
(20, 1, '2025-08-01 20:40:01', 'non_tunai', 515666, 'REF4875753762', 'Belum Lunas', 82),
(21, 34, '2025-09-22 15:22:50', 'tunai', 201451, 'REF1708812301', 'Belum Lunas', 2),
(22, 38, '2025-10-21 11:40:38', 'tunai', 486105, 'REF3242849002', 'Lunas', 68),
(23, 42, '2025-01-29 10:45:09', 'non_tunai', 555780, 'REF6999482465', 'Belum Lunas', 80),
(24, 4, '2025-06-15 18:48:46', 'tunai', 209315, 'REF2597585209', 'Belum Lunas', 35),
(25, 64, '2025-11-27 15:44:03', 'tunai', 123256, 'REF7027884041', 'Belum Lunas', 21),
(26, 94, '2025-02-01 14:07:45', 'tunai', 579578, 'REF6202441002', 'Belum Lunas', 29),
(27, 42, '2025-10-19 21:53:25', 'tunai', 717757, 'REF8673856427', 'Belum Lunas', 55),
(28, 43, '2025-09-08 21:28:40', 'tunai', 223082, 'REF1076854307', 'Lunas', 29),
(29, 45, '2025-10-20 10:34:07', 'tunai', 581944, 'REF5075159419', 'Lunas', 22),
(30, 38, '2025-10-09 12:22:22', 'tunai', 751789, 'REF6062316700', 'Lunas', 24),
(31, 1, '2025-03-24 17:36:06', 'non_tunai', 349202, 'REF2897247791', 'Lunas', 2),
(32, 25, '2025-04-14 19:36:26', 'tunai', 284986, 'REF6148733649', 'Belum Lunas', 62),
(33, 56, '2025-10-09 14:49:18', 'tunai', 195450, 'REF9769886222', 'Belum Lunas', 18),
(34, 53, '2025-01-05 10:09:29', 'non_tunai', 733787, 'REF5358708540', 'Lunas', 56),
(35, 97, '2025-07-02 12:38:35', 'non_tunai', 109521, 'REF0760367487', 'Belum Lunas', 55),
(36, 27, '2025-04-02 19:17:45', 'non_tunai', 638674, 'REF5411512171', 'Lunas', 73),
(37, 78, '2025-03-05 06:52:06', 'tunai', 475715, 'REF2150437440', 'Belum Lunas', 3),
(38, 48, '2025-12-08 14:11:34', 'non_tunai', 35566, 'REF6757487783', 'Belum Lunas', 72),
(39, 17, '2025-03-13 02:34:53', 'tunai', 948748, 'REF2742580534', 'Belum Lunas', 28),
(40, 45, '2025-03-27 10:29:45', 'non_tunai', 678611, 'REF5017772364', 'Lunas', 3),
(41, 72, '2025-04-12 20:57:43', 'non_tunai', 630978, 'REF9302994356', 'Lunas', 36),
(42, 80, '2025-10-25 00:53:47', 'tunai', 130897, 'REF4285098114', 'Belum Lunas', 10),
(43, 94, '2025-12-02 01:37:58', 'non_tunai', 187273, 'REF1215626816', 'Lunas', 6),
(44, 40, '2025-05-06 05:34:58', 'tunai', 813204, 'REF1730816090', 'Belum Lunas', 44),
(45, 59, '2025-05-28 23:33:38', 'non_tunai', 117520, 'REF9502359080', 'Belum Lunas', 49),
(46, 79, '2025-05-03 14:33:11', 'tunai', 896299, 'REF3102618122', 'Belum Lunas', 31),
(47, 74, '2025-08-04 22:25:52', 'tunai', 28733, 'REF4054710715', 'Lunas', 89),
(48, 27, '2025-05-02 18:02:27', 'tunai', 993890, 'REF0108271969', 'Lunas', 23),
(49, 9, '2025-02-02 03:45:11', 'tunai', 257625, 'REF5861070703', 'Lunas', 49),
(50, 21, '2025-07-12 13:20:59', 'tunai', 963846, 'REF2620164941', 'Belum Lunas', 87),
(51, 83, '2025-03-29 09:27:45', 'non_tunai', 311373, 'REF7230059980', 'Belum Lunas', 2),
(52, 21, '2025-01-18 03:31:27', 'tunai', 804218, 'REF9323520866', 'Belum Lunas', 65),
(53, 22, '2025-09-13 13:07:13', 'tunai', 920930, 'REF7321695788', 'Lunas', 90),
(54, 32, '2025-10-25 21:53:46', 'tunai', 636254, 'REF9310180987', 'Belum Lunas', 37),
(55, 53, '2025-03-04 23:11:12', 'non_tunai', 214511, 'REF3361152050', 'Belum Lunas', 69),
(56, 27, '2025-10-01 18:45:07', 'tunai', 33637, 'REF4213316676', 'Belum Lunas', 66),
(57, 78, '2025-12-06 13:08:54', 'tunai', 708425, 'REF0438283921', 'Belum Lunas', 95),
(58, 64, '2025-12-09 08:17:29', 'tunai', 600633, 'REF6789646457', 'Lunas', 37),
(59, 16, '2025-07-28 08:54:05', 'non_tunai', 224786, 'REF5451744428', 'Belum Lunas', 23),
(60, 39, '2025-09-28 00:42:53', 'tunai', 811550, 'REF0626847833', 'Belum Lunas', 95),
(61, 37, '2025-07-12 06:49:52', 'non_tunai', 717906, 'REF8825680737', 'Lunas', 44),
(62, 61, '2025-03-27 19:08:32', 'tunai', 123204, 'REF1839547396', 'Lunas', 94),
(63, 27, '2025-03-27 14:57:13', 'non_tunai', 522322, 'REF7763204930', 'Belum Lunas', 33),
(64, 13, '2025-01-13 00:32:29', 'non_tunai', 774370, 'REF0583924951', 'Belum Lunas', 23),
(65, 48, '2025-04-02 18:31:31', 'non_tunai', 857433, 'REF9988647480', 'Lunas', 90),
(66, 68, '2025-05-15 05:57:11', 'non_tunai', 820120, 'REF8070619881', 'Belum Lunas', 92),
(67, 42, '2025-08-10 02:52:49', 'tunai', 100073, 'REF6369361066', 'Belum Lunas', 97),
(68, 71, '2025-05-06 07:57:04', 'tunai', 121949, 'REF1121303543', 'Lunas', 66),
(69, 59, '2025-02-15 15:46:23', 'non_tunai', 638789, 'REF1991296008', 'Belum Lunas', 7),
(70, 93, '2025-04-04 04:58:08', 'non_tunai', 656101, 'REF1745514158', 'Belum Lunas', 1),
(71, 40, '2025-12-03 23:14:00', 'tunai', 695014, 'REF3446546765', 'Lunas', 34),
(72, 47, '2025-11-29 01:59:52', 'tunai', 688960, 'REF5171943068', 'Lunas', 81),
(73, 54, '2025-11-25 07:36:16', 'tunai', 180061, 'REF2992142852', 'Belum Lunas', 73),
(74, 67, '2025-06-02 11:11:57', 'tunai', 124904, 'REF1649773295', 'Belum Lunas', 86),
(75, 54, '2025-06-26 03:31:43', 'non_tunai', 76843, 'REF2583669398', 'Lunas', 71),
(76, 70, '2025-12-11 06:07:28', 'non_tunai', 406461, 'REF4025768440', 'Lunas', 66),
(77, 79, '2025-03-03 23:57:47', 'tunai', 484693, 'REF9044001247', 'Belum Lunas', 24),
(78, 11, '2025-12-05 01:52:40', 'non_tunai', 110518, 'REF8397260156', 'Lunas', 86),
(79, 34, '2025-03-30 01:34:11', 'tunai', 878610, 'REF5661438467', 'Belum Lunas', 49),
(80, 94, '2025-06-15 05:30:47', 'non_tunai', 394486, 'REF6508324146', 'Belum Lunas', 75),
(81, 23, '2025-10-01 02:41:20', 'tunai', 27872, 'REF3245936819', 'Lunas', 31),
(82, 93, '2025-09-11 06:32:36', 'non_tunai', 360136, 'REF0491792434', 'Belum Lunas', 93),
(83, 42, '2025-12-16 04:41:51', 'tunai', 300328, 'REF9139012308', 'Belum Lunas', 100),
(84, 1, '2025-07-04 15:10:07', 'tunai', 42098, 'REF7247430101', 'Lunas', 62),
(85, 2, '2025-08-03 00:03:53', 'tunai', 188830, 'REF8339771778', 'Lunas', 60),
(86, 83, '2025-06-09 20:15:16', 'non_tunai', 746436, 'REF8760576780', 'Belum Lunas', 30),
(87, 30, '2025-03-18 07:28:55', 'non_tunai', 588246, 'REF5986135420', 'Lunas', 10),
(88, 5, '2025-01-28 18:47:12', 'non_tunai', 615314, 'REF7901255631', 'Lunas', 64),
(89, 89, '2025-04-24 21:30:26', 'tunai', 500932, 'REF1610314089', 'Lunas', 22),
(90, 86, '2025-04-29 04:47:50', 'tunai', 281130, 'REF5501158923', 'Belum Lunas', 75),
(91, 89, '2025-04-07 23:03:33', 'tunai', 81940, 'REF0228939600', 'Belum Lunas', 26),
(92, 74, '2025-04-23 20:03:56', 'non_tunai', 915974, 'REF3529345057', 'Belum Lunas', 28),
(93, 56, '2025-01-14 11:44:03', 'non_tunai', 914428, 'REF9694727802', 'Lunas', 19),
(94, 99, '2025-08-04 18:42:31', 'non_tunai', 81599, 'REF5121149953', 'Belum Lunas', 97),
(95, 35, '2025-10-31 09:48:23', 'tunai', 931069, 'REF3479809211', 'Lunas', 26),
(96, 27, '2025-07-31 03:35:07', 'tunai', 347718, 'REF2060820069', 'Lunas', 63),
(97, 31, '2025-10-03 16:44:55', 'tunai', 804666, 'REF6936139666', 'Lunas', 77),
(98, 61, '2025-11-01 15:44:54', 'tunai', 46464, 'REF6563145942', 'Lunas', 59),
(99, 26, '2025-09-24 07:46:55', 'non_tunai', 250339, 'REF1151083162', 'Belum Lunas', 83),
(100, 19, '2025-01-20 16:58:19', 'tunai', 943720, 'REF7056258843', 'Belum Lunas', 52),
(101, 45, '2025-08-18 11:07:38', 'tunai', 204819, 'REF101', 'Lunas', 76),
(102, 22, '2025-04-24 03:00:39', 'tunai', 905125, 'REF102', 'Belum Lunas', 72),
(103, 37, '2025-01-24 10:07:15', 'tunai', 38287, 'REF103', 'Belum Lunas', 21),
(104, 95, '2025-01-18 13:11:08', 'non_tunai', 402604, 'REF104', 'Belum Lunas', 64),
(105, 5, '2025-03-28 13:42:07', 'non_tunai', 163678, 'REF105', 'Belum Lunas', 52),
(106, 29, '2025-11-24 19:36:50', 'non_tunai', 408415, 'REF106', 'Belum Lunas', 21),
(107, 23, '2025-03-26 20:00:37', 'non_tunai', 109200, 'REF107', 'Belum Lunas', 60),
(108, 9, '2025-10-11 10:55:41', 'non_tunai', 253208, 'REF108', 'Belum Lunas', 44),
(109, 59, '2025-09-04 06:59:24', 'non_tunai', 164290, 'REF109', 'Lunas', 49),
(110, 64, '2025-05-26 00:20:54', 'non_tunai', 246139, 'REF110', 'Belum Lunas', 86),
(111, 21, '2025-11-25 15:15:53', 'tunai', 91715, 'REF111', 'Belum Lunas', 29),
(112, 45, '2025-03-29 03:15:09', 'non_tunai', 699624, 'REF112', 'Belum Lunas', 81),
(113, 2, '2025-05-05 21:04:51', 'tunai', 284742, 'REF113', 'Lunas', 52),
(114, 6, '2025-12-08 02:02:55', 'non_tunai', 31711, 'REF114', 'Lunas', 71),
(115, 61, '2025-08-19 09:35:08', 'tunai', 841441, 'REF115', 'Lunas', 86),
(116, 72, '2025-01-12 08:57:12', 'non_tunai', 74106, 'REF116', 'Belum Lunas', 59),
(117, 29, '2025-09-07 03:13:46', 'tunai', 243438, 'REF117', 'Belum Lunas', 95),
(118, 6, '2025-04-15 00:00:46', 'tunai', 284029, 'REF118', 'Lunas', 10),
(119, 4, '2025-07-15 11:11:33', 'non_tunai', 953353, 'REF119', 'Belum Lunas', 26),
(120, 51, '2025-02-25 18:17:17', 'tunai', 936703, 'REF120', 'Belum Lunas', 77),
(121, 31, '2025-04-18 23:38:27', 'tunai', 486402, 'REF121', 'Lunas', 93),
(122, 9, '2025-03-14 01:38:45', 'tunai', 336794, 'REF122', 'Lunas', 52),
(123, 48, '2025-10-27 03:13:20', 'tunai', 548343, 'REF123', 'Lunas', 82),
(124, 53, '2025-10-25 05:38:16', 'tunai', 204143, 'REF124', 'Belum Lunas', 55),
(125, 94, '2025-10-14 05:13:44', 'tunai', 325209, 'REF125', 'Lunas', 85),
(126, 16, '2025-11-09 11:58:14', 'non_tunai', 450211, 'REF126', 'Lunas', 55),
(127, 93, '2025-02-10 18:01:01', 'non_tunai', 357347, 'REF127', 'Belum Lunas', 81),
(128, 38, '2025-11-29 18:52:32', 'non_tunai', 245264, 'REF128', 'Belum Lunas', 74),
(129, 26, '2025-06-14 12:38:31', 'non_tunai', 151770, 'REF129', 'Belum Lunas', 81),
(130, 30, '2025-05-10 08:10:39', 'tunai', 916758, 'REF130', 'Belum Lunas', 21),
(131, 9, '2025-09-16 04:30:30', 'tunai', 578173, 'REF131', 'Lunas', 85),
(132, 68, '2025-08-11 13:36:24', 'non_tunai', 567786, 'REF132', 'Lunas', 23),
(133, 6, '2025-05-15 02:33:01', 'tunai', 83219, 'REF133', 'Belum Lunas', 74),
(134, 22, '2025-06-13 08:22:15', 'tunai', 486498, 'REF134', 'Lunas', 56),
(135, 35, '2025-10-27 00:24:45', 'non_tunai', 478504, 'REF135', 'Lunas', 69),
(136, 79, '2025-05-10 12:40:12', 'tunai', 688465, 'REF136', 'Belum Lunas', 73),
(137, 56, '2025-07-28 13:35:47', 'non_tunai', 958066, 'REF137', 'Lunas', 59),
(138, 40, '2025-12-21 07:25:17', 'non_tunai', 637372, 'REF138', 'Lunas', 83),
(139, 67, '2025-01-30 04:35:20', 'tunai', 281380, 'REF139', 'Belum Lunas', 94),
(140, 56, '2025-11-23 14:21:35', 'non_tunai', 198308, 'REF140', 'Belum Lunas', 50),
(141, 61, '2025-03-28 04:44:00', 'non_tunai', 447475, 'REF141', 'Lunas', 28),
(142, 31, '2025-09-19 19:39:24', 'tunai', 73724, 'REF142', 'Belum Lunas', 60),
(143, 71, '2025-06-13 13:51:47', 'non_tunai', 142805, 'REF143', 'Lunas', 6),
(144, 70, '2025-05-30 10:19:47', 'tunai', 206658, 'REF144', 'Lunas', 63),
(145, 14, '2025-09-24 12:57:57', 'non_tunai', 55753, 'REF145', 'Lunas', 69),
(146, 27, '2025-04-07 17:16:59', 'non_tunai', 363787, 'REF146', 'Lunas', 18),
(147, 56, '2025-08-28 04:02:17', 'non_tunai', 818513, 'REF147', 'Belum Lunas', 2),
(148, 26, '2025-09-29 14:08:06', 'tunai', 835613, 'REF148', 'Lunas', 85),
(149, 17, '2025-10-07 18:02:24', 'non_tunai', 922448, 'REF149', 'Lunas', 33),
(150, 13, '2025-06-01 13:26:55', 'tunai', 830353, 'REF150', 'Belum Lunas', 44),
(151, 23, '2025-08-12 17:27:01', 'non_tunai', 475683, 'REF151', 'Lunas', 74),
(152, 21, '2025-02-16 00:09:01', 'tunai', 627046, 'REF152', 'Belum Lunas', 81),
(153, 72, '2025-12-11 20:36:29', 'non_tunai', 694460, 'REF153', 'Lunas', 71),
(154, 64, '2025-06-11 10:07:37', 'non_tunai', 598291, 'REF154', 'Belum Lunas', 64),
(155, 23, '2025-04-22 18:51:23', 'tunai', 668626, 'REF155', 'Belum Lunas', 24),
(156, 80, '2025-06-02 18:39:23', 'non_tunai', 738718, 'REF156', 'Lunas', 56),
(157, 83, '2025-03-13 22:15:17', 'non_tunai', 41009, 'REF157', 'Lunas', 29),
(158, 74, '2025-02-27 20:06:02', 'non_tunai', 877107, 'REF158', 'Lunas', 31),
(159, 71, '2025-02-02 21:55:01', 'tunai', 70474, 'REF159', 'Lunas', 87),
(160, 11, '2025-09-14 06:01:17', 'non_tunai', 291206, 'REF160', 'Belum Lunas', 95),
(161, 45, '2025-10-25 11:27:49', 'tunai', 135843, 'REF161', 'Lunas', 50),
(162, 16, '2025-05-24 07:22:10', 'non_tunai', 462423, 'REF162', 'Lunas', 93),
(163, 67, '2025-01-21 18:44:01', 'non_tunai', 739413, 'REF163', 'Belum Lunas', 49),
(164, 92, '2025-08-27 03:20:46', 'tunai', 853088, 'REF164', 'Lunas', 31),
(165, 86, '2025-01-09 10:25:26', 'non_tunai', 177732, 'REF165', 'Lunas', 66),
(166, 64, '2025-06-12 15:49:36', 'tunai', 950169, 'REF166', 'Belum Lunas', 83),
(167, 16, '2025-07-19 08:23:07', 'tunai', 199311, 'REF167', 'Belum Lunas', 51),
(168, 45, '2025-02-03 16:25:02', 'tunai', 403273, 'REF168', 'Lunas', 72),
(169, 70, '2025-08-17 23:44:56', 'tunai', 616992, 'REF169', 'Belum Lunas', 50),
(170, 29, '2025-11-13 01:14:32', 'non_tunai', 227474, 'REF170', 'Belum Lunas', 6),
(171, 72, '2025-06-09 18:11:14', 'tunai', 917068, 'REF171', 'Lunas', 33),
(172, 32, '2025-04-21 23:11:34', 'non_tunai', 467560, 'REF172', 'Belum Lunas', 73),
(173, 37, '2025-10-15 19:45:57', 'tunai', 474522, 'REF173', 'Lunas', 6),
(174, 2, '2025-08-23 21:13:10', 'tunai', 885332, 'REF174', 'Belum Lunas', 30),
(175, 95, '2025-06-16 19:37:55', 'non_tunai', 813569, 'REF175', 'Lunas', 81),
(176, 42, '2025-05-28 03:32:07', 'tunai', 127956, 'REF176', 'Lunas', 29),
(177, 54, '2025-03-12 21:39:09', 'non_tunai', 400519, 'REF177', 'Belum Lunas', 44),
(178, 55, '2025-12-08 00:18:25', 'tunai', 547176, 'REF178', 'Belum Lunas', 64),
(179, 21, '2025-01-11 02:20:59', 'tunai', 786854, 'REF179', 'Belum Lunas', 93),
(180, 61, '2025-08-30 21:05:10', 'tunai', 477220, 'REF180', 'Belum Lunas', 74),
(181, 48, '2025-05-19 10:53:39', 'non_tunai', 567413, 'REF181', 'Belum Lunas', 100),
(182, 70, '2025-12-08 10:47:25', 'tunai', 835334, 'REF182', 'Belum Lunas', 76),
(183, 9, '2025-03-11 03:40:14', 'tunai', 831734, 'REF183', 'Lunas', 33),
(184, 34, '2025-11-27 07:30:52', 'non_tunai', 124118, 'REF184', 'Lunas', 90),
(185, 35, '2025-04-23 03:27:47', 'non_tunai', 259849, 'REF185', 'Belum Lunas', 90),
(186, 30, '2025-04-19 18:36:14', 'tunai', 766525, 'REF186', 'Lunas', 68),
(187, 32, '2025-08-05 15:45:51', 'tunai', 97730, 'REF187', 'Belum Lunas', 69),
(188, 93, '2025-09-20 01:04:40', 'non_tunai', 106252, 'REF188', 'Lunas', 73),
(189, 94, '2025-10-03 10:25:12', 'tunai', 774900, 'REF189', 'Lunas', 52),
(190, 72, '2025-10-18 07:32:59', 'tunai', 129105, 'REF190', 'Lunas', 63),
(191, 53, '2025-06-13 16:21:26', 'tunai', 64024, 'REF191', 'Lunas', 31),
(192, 59, '2025-11-08 17:17:33', 'non_tunai', 830657, 'REF192', 'Belum Lunas', 50),
(193, 79, '2025-03-10 21:32:20', 'tunai', 84855, 'REF193', 'Belum Lunas', 37),
(194, 67, '2025-02-07 15:27:47', 'tunai', 648271, 'REF194', 'Belum Lunas', 97),
(195, 74, '2025-03-26 05:21:52', 'tunai', 246522, 'REF195', 'Lunas', 85),
(196, 19, '2025-11-06 05:30:34', 'tunai', 626273, 'REF196', 'Belum Lunas', 62),
(197, 9, '2025-10-17 15:09:08', 'non_tunai', 644321, 'REF197', 'Belum Lunas', 82),
(198, 61, '2025-01-03 19:47:09', 'tunai', 370770, 'REF198', 'Belum Lunas', 3),
(199, 9, '2025-09-10 09:43:03', 'tunai', 894088, 'REF199', 'Belum Lunas', 77),
(200, 64, '2025-02-07 17:12:53', 'tunai', 678443, 'REF200', 'Belum Lunas', 100),
(201, 206, '2025-12-21 18:18:11', 'non_tunai', 50000, 'QRIS|QR-INV-206', 'Lunas', 0),
(202, 207, '2025-12-21 18:21:19', 'non_tunai', 50000, 'QRIS|QR-INV-207', 'Lunas', 0);

--
-- Trigger `pembayaran`
--
DELIMITER $$
CREATE TRIGGER `ai_pembayaran_after` AFTER INSERT ON `pembayaran` FOR EACH ROW BEGIN
  -- update status pesanan jadi LUNAS
  UPDATE pesanan
  SET status_pesanan = 'LUNAS'
  WHERE pesanan_id = NEW.pesanan_id;

  -- LOG permanen (InnoDB)
  INSERT INTO audit_event_log(actor_user, event_type, table_name, ref_id, detail)
  VALUES (
    CURRENT_USER(),
    'PAYMENT_INSERT',
    'pembayaran',
    NEW.pembayaran_id,
    CONCAT(
      'pesanan_id=', NEW.pesanan_id,
      ', metode=', NEW.metode_pembayaran,
      ', jumlah_bayar=', NEW.jumlah_bayar,
      ', status=', NEW.status_pembayaran
    )
  );

  -- UNLOG (MEMORY)
  INSERT INTO audit_event_unlog(actor_user, event_type, table_name, ref_id, detail)
  VALUES (
    CURRENT_USER(),
    'PAYMENT_INSERT',
    'pembayaran',
    NEW.pembayaran_id,
    CONCAT('pesanan_id=', NEW.pesanan_id)
  );
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `bi_pembayaran_validate` BEFORE INSERT ON `pembayaran` FOR EACH ROW BEGIN
  DECLARE v_total DECIMAL(12,2);

  -- pastikan pesanan ada & ambil total
  SELECT total_pesanan
    INTO v_total
  FROM pesanan
  WHERE pesanan_id = NEW.pesanan_id
  LIMIT 1;

  IF v_total IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Pesanan tidak ditemukan.';
  END IF;

  -- validasi jumlah bayar
  IF NEW.jumlah_bayar < v_total THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Jumlah bayar kurang dari total pesanan.';
  END IF;

  -- default status pembayaran
  IF NEW.status_pembayaran IS NULL OR NEW.status_pembayaran = '' THEN
    SET NEW.status_pembayaran = 'BERHASIL';
  END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struktur dari tabel `pembelian`
--

CREATE TABLE `pembelian` (
  `pembelian_id` int(11) NOT NULL,
  `supplier_id` int(11) DEFAULT NULL,
  `pesanan_id` int(11) DEFAULT NULL,
  `pelanggan_id` int(11) DEFAULT NULL,
  `tanggal_pembelian` date DEFAULT NULL,
  `total_biaya` decimal(12,2) DEFAULT NULL,
  `status` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `pembelian`
--

INSERT INTO `pembelian` (`pembelian_id`, `supplier_id`, `pesanan_id`, `pelanggan_id`, `tanggal_pembelian`, `total_biaya`, `status`) VALUES
(1, 46, 27, 70, '2025-04-24', 8001578.97, 'Dibatalkan'),
(2, 29, 69, 30, '2025-09-14', 5960667.76, 'Pending'),
(3, 39, 82, 67, '2025-07-13', 2070317.00, 'Pending'),
(4, 5, 100, 100, '2025-10-04', 5585779.66, 'Pending'),
(5, 44, 51, 72, '2025-05-15', 7927871.89, 'Dibatalkan'),
(6, 5, 65, 31, '2025-01-19', 7571440.71, 'Selesai'),
(7, 21, 40, 92, '2025-10-31', 8127099.47, 'Dibatalkan'),
(8, 36, 96, 69, '2025-01-20', 1947992.63, 'Dibatalkan'),
(9, 5, 7, 95, '2025-11-24', 7030056.50, 'Dibatalkan'),
(10, 10, 93, 41, '2025-10-26', 1548248.40, 'Selesai'),
(11, 11, 95, 52, '2025-01-22', 2858093.02, 'Pending'),
(12, 31, 46, 32, '2025-11-07', 4543428.18, 'Selesai'),
(13, 35, 30, 61, '2025-01-24', 2113735.29, 'Pending'),
(14, 3, 83, 14, '2025-05-15', 625644.21, 'Dibatalkan'),
(15, 27, 62, 89, '2025-03-18', 7103768.53, 'Selesai'),
(16, 9, 39, 42, '2025-07-17', 8294793.21, 'Selesai'),
(17, 22, 11, 97, '2025-04-20', 2130613.68, 'Pending'),
(18, 11, 84, 24, '2025-11-23', 6186299.96, 'Selesai'),
(19, 14, 53, 8, '2025-04-15', 4112095.11, 'Selesai'),
(20, 6, 74, 37, '2025-11-04', 4766062.13, 'Pending'),
(21, 47, 49, 52, '2025-09-07', 5382331.24, 'Selesai'),
(22, 16, 19, 65, '2025-11-06', 6387144.73, 'Dibatalkan'),
(23, 3, 42, 2, '2025-11-08', 4973210.43, 'Dibatalkan'),
(24, 39, 78, 32, '2025-12-13', 215139.18, 'Pending'),
(25, 19, 87, 99, '2025-12-25', 3510954.73, 'Selesai'),
(26, 40, 68, 78, '2025-05-28', 7237487.09, 'Pending'),
(27, 39, 94, 17, '2025-09-21', 8442097.00, 'Dibatalkan'),
(28, 16, 33, 85, '2025-07-05', 5338335.43, 'Selesai'),
(29, 35, 82, 69, '2025-05-18', 2459709.43, 'Pending'),
(30, 15, 77, 1, '2025-11-11', 2190235.99, 'Dibatalkan'),
(31, 39, 63, 38, '2025-08-08', 8589380.25, 'Pending'),
(32, 28, 78, 41, '2025-10-09', 1724997.08, 'Selesai'),
(33, 22, 95, 27, '2025-10-08', 8667382.07, 'Selesai'),
(34, 6, 47, 16, '2025-04-07', 9886649.39, 'Pending'),
(35, 21, 48, 57, '2025-09-15', 173506.24, 'Dibatalkan'),
(36, 14, 57, 57, '2025-03-07', 2828722.28, 'Dibatalkan'),
(37, 50, 75, 42, '2025-04-16', 9126183.17, 'Pending'),
(38, 25, 38, 79, '2025-10-18', 1699646.92, 'Dibatalkan'),
(39, 35, 81, 72, '2025-12-22', 6786391.33, 'Pending'),
(40, 23, 56, 65, '2025-06-26', 4346408.52, 'Dibatalkan'),
(41, 29, 18, 16, '2025-12-18', 8570427.70, 'Pending'),
(42, 28, 18, 60, '2025-01-10', 9205045.95, 'Dibatalkan'),
(43, 50, 29, 71, '2025-06-28', 3760726.25, 'Dibatalkan'),
(44, 2, 93, 89, '2025-02-03', 561598.56, 'Dibatalkan'),
(45, 48, 2, 30, '2025-10-26', 5535750.18, 'Pending'),
(46, 7, 99, 35, '2025-10-22', 8077656.27, 'Pending'),
(47, 26, 24, 58, '2025-10-18', 1437870.13, 'Selesai'),
(48, 36, 76, 53, '2025-11-10', 6123950.52, 'Pending'),
(49, 11, 53, 22, '2025-02-26', 8598986.58, 'Pending'),
(50, 33, 76, 59, '2025-06-20', 6778966.50, 'Selesai'),
(51, 11, 96, 10, '2025-07-22', 446233.25, 'Selesai'),
(52, 42, 82, 89, '2025-10-13', 6708367.14, 'Pending'),
(53, 13, 88, 45, '2025-06-12', 1409328.79, 'Selesai'),
(54, 23, 7, 29, '2025-05-30', 2711015.70, 'Dibatalkan'),
(55, 5, 24, 9, '2025-09-10', 3341048.32, 'Dibatalkan'),
(56, 15, 45, 38, '2025-04-13', 3618202.17, 'Selesai'),
(57, 46, 13, 83, '2025-06-23', 1535901.09, 'Dibatalkan'),
(58, 18, 65, 96, '2025-11-24', 6562633.66, 'Dibatalkan'),
(59, 42, 94, 55, '2025-12-22', 2033741.01, 'Dibatalkan'),
(60, 46, 19, 87, '2025-11-05', 8909774.08, 'Pending'),
(61, 33, 52, 96, '2025-10-07', 4904019.88, 'Selesai'),
(62, 4, 72, 44, '2025-03-04', 1063044.67, 'Selesai'),
(63, 39, 5, 4, '2025-09-09', 4096876.20, 'Selesai'),
(64, 20, 25, 4, '2025-11-29', 6193855.56, 'Dibatalkan'),
(65, 10, 28, 14, '2025-07-27', 9465697.42, 'Pending'),
(66, 5, 44, 31, '2025-09-06', 6094485.59, 'Pending'),
(67, 41, 74, 31, '2025-02-28', 4140949.19, 'Selesai'),
(68, 21, 38, 32, '2025-12-17', 3481232.55, 'Selesai'),
(69, 21, 45, 5, '2025-04-13', 8274318.56, 'Selesai'),
(70, 4, 31, 39, '2025-07-19', 8201525.19, 'Pending'),
(71, 37, 83, 10, '2025-07-30', 8443243.14, 'Pending'),
(72, 42, 15, 53, '2025-12-28', 4281051.15, 'Dibatalkan'),
(73, 29, 33, 70, '2025-06-14', 5381851.06, 'Pending'),
(74, 32, 19, 4, '2025-09-03', 4171808.56, 'Pending'),
(75, 42, 93, 90, '2025-03-09', 4769694.68, 'Dibatalkan'),
(76, 20, 58, 3, '2025-05-09', 378836.44, 'Selesai'),
(77, 37, 82, 84, '2025-01-07', 5745044.83, 'Pending'),
(78, 12, 20, 34, '2025-08-04', 5138550.00, 'Pending'),
(79, 4, 47, 46, '2025-06-26', 3451211.90, 'Selesai'),
(80, 25, 74, 42, '2025-07-04', 4634917.21, 'Dibatalkan'),
(81, 11, 55, 76, '2025-06-27', 4314692.72, 'Dibatalkan'),
(82, 32, 3, 5, '2025-03-19', 4629052.69, 'Selesai'),
(83, 46, 89, 26, '2025-11-12', 9554035.76, 'Pending'),
(84, 20, 30, 82, '2025-02-10', 5166276.11, 'Dibatalkan'),
(85, 13, 19, 17, '2025-03-03', 1985052.78, 'Selesai'),
(86, 2, 29, 19, '2025-11-20', 6711429.50, 'Pending'),
(87, 45, 49, 26, '2025-04-12', 3565639.62, 'Selesai'),
(88, 2, 8, 20, '2025-07-02', 7127349.69, 'Selesai'),
(89, 14, 63, 81, '2025-11-05', 6349493.08, 'Selesai'),
(90, 10, 15, 56, '2025-10-02', 8539518.73, 'Pending'),
(91, 38, 88, 87, '2025-02-02', 5249193.49, 'Pending'),
(92, 48, 75, 25, '2025-09-08', 8115876.48, 'Dibatalkan'),
(93, 41, 20, 12, '2025-04-25', 7872132.45, 'Dibatalkan'),
(94, 31, 76, 95, '2025-02-02', 6545864.62, 'Selesai'),
(95, 7, 84, 50, '2025-06-04', 1803062.50, 'Dibatalkan'),
(96, 22, 69, 2, '2025-02-16', 6831121.41, 'Dibatalkan'),
(97, 31, 41, 40, '2025-04-28', 6280329.14, 'Pending'),
(98, 21, 33, 47, '2025-12-20', 8375800.59, 'Selesai'),
(99, 7, 65, 11, '2025-04-28', 2964038.14, 'Selesai'),
(100, 40, 5, 98, '2025-11-12', 5701263.90, 'Selesai'),
(101, 5, 29, 41, '2025-11-20', 630454.56, 'Pending'),
(102, 22, 27, 85, '2025-09-02', 3033392.64, 'Dibatalkan'),
(103, 23, 2, 83, '2025-02-03', 981772.14, 'Selesai'),
(104, 16, 5, 29, '2025-09-23', 2307666.26, 'Dibatalkan'),
(105, 18, 29, 1, '2025-09-13', 2124772.19, 'Dibatalkan'),
(106, 44, 74, 4, '2025-08-30', 280174.52, 'Dibatalkan'),
(107, 25, 95, 45, '2025-04-08', 1370044.25, 'Pending'),
(108, 19, 68, 100, '2025-09-19', 7088808.13, 'Pending'),
(109, 14, 38, 58, '2025-06-14', 9490269.73, 'Selesai'),
(110, 40, 94, 55, '2025-08-10', 8669139.56, 'Pending'),
(111, 38, 2, 59, '2025-11-11', 4401160.71, 'Pending'),
(112, 11, 52, 81, '2025-06-22', 3998982.59, 'Selesai'),
(113, 29, 76, 83, '2025-06-01', 2434319.17, 'Pending'),
(114, 29, 57, 84, '2025-08-10', 6442296.37, 'Selesai'),
(115, 26, 65, 82, '2025-11-21', 5772146.79, 'Pending'),
(116, 37, 63, 19, '2025-10-26', 975238.28, 'Dibatalkan'),
(117, 29, 76, 90, '2025-12-13', 7563863.51, 'Pending'),
(118, 14, 69, 70, '2025-08-23', 6543795.02, 'Dibatalkan'),
(119, 16, 38, 39, '2025-05-12', 1063686.58, 'Dibatalkan'),
(120, 28, 46, 58, '2025-12-17', 5493805.80, 'Pending'),
(121, 22, 72, 90, '2025-05-03', 4032979.59, 'Selesai'),
(122, 42, 49, 5, '2025-06-18', 323618.28, 'Pending'),
(123, 28, 84, 11, '2025-09-07', 4256455.61, 'Selesai'),
(124, 48, 11, 24, '2025-08-03', 5390123.72, 'Selesai'),
(125, 11, 20, 85, '2025-06-13', 5571308.51, 'Selesai'),
(126, 18, 77, 52, '2025-06-27', 4707877.74, 'Pending'),
(127, 46, 57, 38, '2025-09-27', 5721475.27, 'Pending'),
(128, 5, 87, 20, '2025-01-18', 6281722.99, 'Dibatalkan'),
(129, 31, 56, 30, '2025-03-28', 7710382.74, 'Pending'),
(130, 18, 82, 47, '2025-10-03', 416589.03, 'Selesai'),
(131, 50, 38, 31, '2025-09-11', 6092785.81, 'Selesai'),
(132, 12, 74, 3, '2025-09-17', 6903435.19, 'Dibatalkan'),
(133, 11, 5, 98, '2025-04-25', 4637364.51, 'Dibatalkan'),
(134, 35, 24, 32, '2025-01-18', 2534160.32, 'Selesai'),
(135, 14, 57, 46, '2025-06-19', 4901809.38, 'Dibatalkan'),
(136, 9, 55, 61, '2025-10-17', 366481.73, 'Selesai'),
(137, 36, 69, 90, '2025-07-24', 1022106.71, 'Dibatalkan'),
(138, 16, 69, 60, '2025-12-23', 6079287.59, 'Selesai'),
(139, 50, 99, 16, '2025-11-19', 4257244.65, 'Pending'),
(140, 45, 25, 83, '2025-06-12', 8172794.43, 'Selesai'),
(141, 5, 18, 5, '2025-11-11', 5825809.41, 'Selesai'),
(142, 39, 69, 12, '2025-10-25', 8163225.15, 'Pending'),
(143, 23, 83, 44, '2025-03-26', 820458.96, 'Pending'),
(144, 37, 19, 40, '2025-09-24', 5336108.64, 'Dibatalkan'),
(145, 45, 40, 57, '2025-05-24', 4056311.11, 'Dibatalkan'),
(146, 6, 83, 96, '2025-05-04', 2357942.20, 'Selesai'),
(147, 21, 76, 96, '2025-09-28', 4654023.45, 'Pending'),
(148, 36, 58, 14, '2025-01-13', 4695939.19, 'Selesai'),
(149, 45, 69, 82, '2025-09-11', 8914834.77, 'Dibatalkan'),
(150, 18, 89, 38, '2025-02-27', 1118612.61, 'Selesai'),
(151, 36, 29, 53, '2025-09-06', 2937694.84, 'Dibatalkan'),
(152, 37, 3, 46, '2025-07-14', 5266104.46, 'Selesai'),
(153, 18, 99, 30, '2025-07-27', 3918231.65, 'Pending'),
(154, 25, 57, 81, '2025-07-29', 1102098.51, 'Dibatalkan'),
(155, 14, 8, 10, '2025-08-07', 8403827.33, 'Selesai'),
(156, 33, 25, 78, '2025-12-08', 2416646.79, 'Dibatalkan'),
(157, 23, 19, 25, '2025-03-09', 7588243.59, 'Dibatalkan'),
(158, 45, 15, 25, '2025-04-26', 4241786.05, 'Dibatalkan'),
(159, 40, 25, 97, '2025-08-23', 1626289.73, 'Selesai'),
(160, 23, 15, 53, '2025-08-28', 3487722.81, 'Dibatalkan'),
(161, 3, 24, 100, '2025-07-01', 725055.84, 'Selesai'),
(162, 26, 75, 82, '2025-07-02', 4820758.40, 'Pending'),
(163, 20, 56, 50, '2025-10-12', 3082126.16, 'Selesai'),
(164, 18, 82, 84, '2025-05-05', 9610693.00, 'Selesai'),
(165, 26, 45, 78, '2025-12-15', 1105411.36, 'Selesai'),
(166, 3, 65, 81, '2025-04-11', 5855775.80, 'Selesai'),
(167, 28, 62, 95, '2025-09-19', 7868684.66, 'Selesai'),
(168, 12, 8, 19, '2025-03-08', 2443072.11, 'Selesai'),
(169, 36, 27, 1, '2025-03-29', 912905.95, 'Pending'),
(170, 50, 81, 87, '2025-09-25', 1994209.48, 'Dibatalkan'),
(171, 10, 27, 61, '2025-03-27', 2190254.52, 'Dibatalkan'),
(172, 39, 42, 42, '2025-07-01', 8007225.62, 'Dibatalkan'),
(173, 29, 24, 24, '2025-11-07', 5746450.42, 'Dibatalkan'),
(174, 42, 96, 96, '2025-04-12', 4349271.55, 'Selesai'),
(175, 40, 8, 45, '2025-07-18', 7360695.35, 'Selesai'),
(176, 16, 65, 83, '2025-09-09', 6845395.22, 'Dibatalkan'),
(177, 27, 18, 17, '2025-06-24', 4267668.32, 'Selesai'),
(178, 28, 31, 67, '2025-10-28', 8296101.90, 'Pending'),
(179, 9, 94, 3, '2025-06-11', 3363641.67, 'Dibatalkan'),
(180, 19, 88, 14, '2025-12-06', 5485948.07, 'Selesai'),
(181, 41, 45, 34, '2025-10-22', 1384782.84, 'Selesai'),
(182, 3, 88, 84, '2025-06-07', 4314633.29, 'Pending'),
(183, 50, 39, 98, '2025-03-04', 7404924.84, 'Dibatalkan'),
(184, 31, 83, 3, '2025-07-28', 4583786.42, 'Dibatalkan'),
(185, 9, 55, 46, '2025-07-06', 1900092.65, 'Dibatalkan'),
(186, 26, 11, 30, '2025-01-31', 8924478.20, 'Selesai'),
(187, 3, 40, 39, '2025-08-18', 1282331.18, 'Selesai'),
(188, 23, 63, 57, '2025-08-05', 9614516.09, 'Selesai'),
(189, 11, 7, 9, '2025-02-21', 1706095.04, 'Dibatalkan'),
(190, 12, 3, 76, '2025-01-21', 3646769.03, 'Dibatalkan'),
(191, 11, 96, 27, '2025-03-19', 3954775.86, 'Pending'),
(192, 19, 29, 46, '2025-06-12', 485342.48, 'Pending'),
(193, 21, 45, 82, '2025-02-07', 4424226.31, 'Dibatalkan'),
(194, 27, 51, 10, '2025-11-25', 4953363.55, 'Dibatalkan'),
(195, 38, 58, 22, '2025-02-21', 6926710.40, 'Dibatalkan'),
(196, 19, 20, 2, '2025-06-20', 932454.38, 'Selesai'),
(197, 3, 15, 9, '2025-10-06', 9789547.23, 'Selesai'),
(198, 23, 52, 1, '2025-02-07', 7088381.05, 'Selesai'),
(199, 20, 24, 83, '2025-08-04', 8334810.10, 'Dibatalkan'),
(200, 4, 63, 12, '2025-07-02', 1352148.95, 'Dibatalkan');

-- --------------------------------------------------------

--
-- Struktur dari tabel `peralatan`
--

CREATE TABLE `peralatan` (
  `jenis_peralatan` varchar(100) NOT NULL,
  `jumlah` int(11) DEFAULT NULL,
  `id_jenis_produk` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `peralatan`
--

INSERT INTO `peralatan` (`jenis_peralatan`, `jumlah`, `id_jenis_produk`) VALUES
('Blender', 70, 89),
('jenis_peralatan', 0, 0),
('Kompor Gas', 65, 42),
('Kursi Plastik', 5, 10),
('Meja Kayu', 25, 86),
('Mixer', 37, 32),
('Panci', 32, 65),
('Saringan Kopi', 13, 23),
('Spatula', 11, 54),
('Teko Kopi', 65, 87),
('Wajan', 44, 68);

-- --------------------------------------------------------

--
-- Struktur dari tabel `pesanan`
--

CREATE TABLE `pesanan` (
  `pesanan_id` int(11) NOT NULL,
  `pelanggan_id` int(11) DEFAULT NULL,
  `tanggal_pesanan` date DEFAULT NULL,
  `total_pesanan` decimal(12,2) DEFAULT NULL,
  `status_pesanan` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `pesanan`
--

INSERT INTO `pesanan` (`pesanan_id`, `pelanggan_id`, `tanggal_pesanan`, `total_pesanan`, `status_pesanan`) VALUES
(1, 85, '2025-01-18', 1557347.02, 'Diproses'),
(2, 82, '2025-02-13', 1581307.03, 'Selesai'),
(3, 43, '2025-02-12', 4385752.21, 'Dibatalkan'),
(4, 69, '2025-07-29', 215764.80, 'Dibatalkan'),
(5, 8, '2025-11-06', 3100517.69, 'Selesai'),
(6, 65, '2025-02-21', 3178763.11, 'Diproses'),
(7, 91, '2025-08-07', 911149.65, 'Diproses'),
(8, 65, '2025-11-08', 994910.23, 'Diproses'),
(9, 51, '2025-09-25', 4843676.97, 'Baru'),
(10, 61, '2025-12-02', 1442840.35, 'Diproses'),
(11, 86, '2025-08-03', 401272.60, 'Baru'),
(12, 32, '2025-05-19', 3043818.03, 'Selesai'),
(13, 100, '2025-12-05', 4240756.19, 'Baru'),
(14, 61, '2025-10-19', 1580925.35, 'Diproses'),
(15, 58, '2025-07-02', 3950309.73, 'Dibatalkan'),
(16, 62, '2025-10-26', 2461294.65, 'Selesai'),
(17, 44, '2025-01-24', 1236368.73, 'Baru'),
(18, 36, '2025-04-13', 1953091.55, 'Diproses'),
(19, 87, '2025-09-28', 3352696.89, 'Baru'),
(20, 61, '2025-07-11', 4430395.73, 'Baru'),
(21, 54, '2025-02-16', 1214768.71, 'Baru'),
(22, 46, '2025-01-10', 579072.46, 'Dibatalkan'),
(23, 26, '2025-06-15', 4033677.40, 'Diproses'),
(24, 44, '2025-02-16', 3288209.82, 'Dibatalkan'),
(25, 20, '2025-08-24', 1018504.20, 'Selesai'),
(26, 94, '2025-08-08', 1301856.84, 'Dibatalkan'),
(27, 24, '2025-07-29', 4186876.06, 'Selesai'),
(28, 15, '2025-11-25', 3816662.50, 'Diproses'),
(29, 67, '2025-05-16', 2469525.65, 'Dibatalkan'),
(30, 45, '2025-03-07', 299851.01, 'Dibatalkan'),
(31, 39, '2025-11-25', 4932850.29, 'Dibatalkan'),
(32, 50, '2025-08-27', 351153.98, 'Dibatalkan'),
(33, 40, '2025-03-10', 4975253.27, 'Baru'),
(34, 24, '2025-04-30', 1581642.42, 'Baru'),
(35, 65, '2025-05-30', 2773520.88, 'Selesai'),
(36, 92, '2025-01-27', 4975787.98, 'Dibatalkan'),
(37, 68, '2025-09-21', 4548153.42, 'Diproses'),
(38, 19, '2025-07-17', 1771130.26, 'Diproses'),
(39, 89, '2025-02-10', 566219.25, 'Dibatalkan'),
(40, 77, '2025-09-10', 2775672.94, 'Baru'),
(41, 74, '2025-10-14', 1712834.58, 'Diproses'),
(42, 7, '2025-09-11', 1385133.54, 'Diproses'),
(43, 78, '2025-07-27', 123656.83, 'Baru'),
(44, 56, '2025-01-26', 2457419.25, 'Diproses'),
(45, 70, '2025-05-19', 4203976.18, 'Diproses'),
(46, 98, '2025-11-09', 4324376.59, 'Selesai'),
(47, 5, '2025-08-30', 485945.33, 'Selesai'),
(48, 65, '2025-08-05', 3916069.44, 'Selesai'),
(49, 72, '2025-07-29', 475041.41, 'Diproses'),
(50, 88, '2025-07-05', 477441.00, 'Dibatalkan'),
(51, 38, '2025-09-01', 399541.36, 'Baru'),
(52, 67, '2025-12-08', 1907522.02, 'Baru'),
(53, 60, '2025-12-11', 2825457.73, 'Diproses'),
(54, 11, '2025-12-10', 1615841.34, 'Dibatalkan'),
(55, 75, '2025-02-06', 4821967.07, 'Selesai'),
(56, 9, '2025-03-24', 3037733.17, 'Diproses'),
(57, 44, '2025-06-11', 244799.53, 'Diproses'),
(58, 99, '2025-12-21', 716050.14, 'Diproses'),
(59, 66, '2025-08-11', 2789637.61, 'Diproses'),
(60, 94, '2025-08-26', 3941138.10, 'Diproses'),
(61, 14, '2025-02-06', 4450949.12, 'Baru'),
(62, 11, '2025-08-05', 4160850.71, 'Selesai'),
(63, 58, '2025-09-18', 4904166.73, 'Selesai'),
(64, 3, '2025-06-19', 890126.31, 'Diproses'),
(65, 14, '2025-09-28', 2473830.12, 'Diproses'),
(66, 42, '2025-11-22', 271125.72, 'Dibatalkan'),
(67, 61, '2025-10-06', 1805571.40, 'Diproses'),
(68, 40, '2025-08-19', 4904178.50, 'Diproses'),
(69, 22, '2025-04-10', 3898718.76, 'Diproses'),
(70, 68, '2025-10-20', 3714232.35, 'Baru'),
(71, 30, '2025-08-03', 351487.64, 'Diproses'),
(72, 16, '2025-01-24', 203356.78, 'Selesai'),
(73, 61, '2025-01-22', 2999665.82, 'Baru'),
(74, 100, '2025-10-26', 1640175.86, 'Selesai'),
(75, 22, '2025-05-22', 3695085.33, 'Dibatalkan'),
(76, 100, '2025-01-03', 4225950.73, 'Selesai'),
(77, 87, '2025-06-25', 2032865.44, 'Selesai'),
(78, 63, '2025-12-16', 2401442.82, 'Dibatalkan'),
(79, 25, '2025-02-27', 2061515.21, 'Selesai'),
(80, 68, '2025-10-28', 3649579.90, 'Diproses'),
(81, 15, '2025-06-26', 2912427.70, 'Baru'),
(82, 45, '2025-07-25', 1147978.30, 'Diproses'),
(83, 80, '2025-04-11', 4986984.00, 'Selesai'),
(84, 38, '2025-03-25', 4663540.24, 'Diproses'),
(85, 20, '2025-08-07', 4959062.59, 'Diproses'),
(86, 25, '2025-02-01', 1245515.86, 'Baru'),
(87, 80, '2025-12-05', 4562098.01, 'Diproses'),
(88, 9, '2025-03-30', 853933.52, 'Selesai'),
(89, 57, '2025-09-22', 867259.85, 'Diproses'),
(90, 23, '2025-06-17', 4610120.50, 'Selesai'),
(91, 49, '2025-03-13', 3871365.58, 'Baru'),
(92, 19, '2025-01-20', 984482.75, 'Selesai'),
(93, 72, '2025-05-27', 1917946.95, 'Selesai'),
(94, 39, '2025-12-03', 544743.21, 'Selesai'),
(95, 22, '2025-01-28', 2956066.80, 'Baru'),
(96, 76, '2025-01-08', 2820610.34, 'Selesai'),
(97, 2, '2025-08-13', 3131142.18, 'Baru'),
(98, 44, '2025-01-11', 2451892.70, 'Selesai'),
(99, 100, '2025-11-24', 3327448.73, 'Dibatalkan'),
(100, 80, '2025-06-14', 3204311.26, 'Selesai'),
(101, 61, '2025-11-11', 3792061.41, 'Dibatalkan'),
(102, 42, '2025-05-07', 3067280.12, 'Baru'),
(103, 44, '2025-07-02', 262231.38, 'Diproses'),
(104, 39, '2025-04-17', 2086293.80, 'Dibatalkan'),
(105, 5, '2025-10-27', 4107872.74, 'Diproses'),
(106, 11, '2025-05-09', 192529.15, 'Baru'),
(107, 60, '2025-03-27', 3169430.94, 'Baru'),
(108, 85, '2025-12-20', 1245061.07, 'Selesai'),
(109, 69, '2025-12-17', 3765057.17, 'Dibatalkan'),
(110, 74, '2025-09-11', 1387222.41, 'Diproses'),
(111, 100, '2025-05-30', 3083464.28, 'Baru'),
(112, 40, '2025-04-13', 1107758.04, 'Diproses'),
(113, 14, '2025-01-18', 1033738.44, 'Baru'),
(114, 9, '2025-03-01', 4303274.43, 'Baru'),
(115, 78, '2025-07-10', 1149497.74, 'Diproses'),
(116, 7, '2025-10-19', 3113413.40, 'Baru'),
(117, 58, '2025-02-10', 2384515.42, 'Dibatalkan'),
(118, 14, '2025-03-16', 2924380.01, 'Selesai'),
(119, 16, '2025-09-16', 3460016.95, 'Baru'),
(120, 15, '2025-01-17', 2368030.59, 'Diproses'),
(121, 20, '2025-10-23', 3656602.56, 'Dibatalkan'),
(122, 44, '2025-06-07', 2245612.79, 'Baru'),
(123, 66, '2025-01-19', 2334094.64, 'Selesai'),
(124, 69, '2025-07-13', 3435941.49, 'Selesai'),
(125, 7, '2025-01-28', 337334.65, 'Diproses'),
(126, 8, '2025-08-16', 2182754.84, 'Selesai'),
(127, 15, '2025-11-03', 4463951.19, 'Dibatalkan'),
(128, 43, '2025-03-06', 4435654.71, 'Diproses'),
(129, 49, '2025-09-10', 2253984.72, 'Dibatalkan'),
(130, 22, '2025-12-19', 797494.93, 'Selesai'),
(131, 74, '2025-04-29', 4121729.86, 'Selesai'),
(132, 26, '2025-10-02', 3267236.99, 'Baru'),
(133, 24, '2025-05-22', 2164465.59, 'Dibatalkan'),
(134, 78, '2025-08-07', 3580925.73, 'Dibatalkan'),
(135, 80, '2025-10-18', 453076.00, 'Selesai'),
(136, 36, '2025-01-31', 2024794.44, 'Selesai'),
(137, 65, '2025-04-16', 3810108.71, 'Dibatalkan'),
(138, 76, '2025-04-05', 702931.63, 'Diproses'),
(139, 42, '2025-11-03', 3373366.70, 'Dibatalkan'),
(140, 85, '2025-10-30', 2119084.59, 'Baru'),
(141, 68, '2025-11-10', 986839.39, 'Baru'),
(142, 85, '2025-10-22', 3587052.36, 'Dibatalkan'),
(143, 54, '2025-03-07', 4624098.69, 'Dibatalkan'),
(144, 39, '2025-12-15', 726751.09, 'Dibatalkan'),
(145, 45, '2025-11-05', 4261517.65, 'Diproses'),
(146, 56, '2025-09-10', 568755.83, 'Selesai'),
(147, 19, '2025-05-24', 3002240.04, 'Dibatalkan'),
(148, 32, '2025-09-27', 2931388.45, 'Diproses'),
(149, 94, '2025-11-30', 1021742.78, 'Baru'),
(150, 63, '2025-11-18', 4253417.88, 'Dibatalkan'),
(151, 78, '2025-09-21', 2802470.70, 'Dibatalkan'),
(152, 98, '2025-10-20', 4801068.34, 'Selesai'),
(153, 3, '2025-04-23', 1101974.22, 'Selesai'),
(154, 57, '2025-01-27', 1586359.08, 'Selesai'),
(155, 99, '2025-06-30', 1861015.61, 'Dibatalkan'),
(156, 30, '2025-03-13', 4655901.05, 'Selesai'),
(157, 70, '2025-05-02', 4400904.13, 'Selesai'),
(158, 70, '2025-04-14', 2425481.44, 'Diproses'),
(159, 98, '2025-06-10', 4155559.36, 'Dibatalkan'),
(160, 88, '2025-05-29', 480394.77, 'Dibatalkan'),
(161, 85, '2025-06-21', 2532954.04, 'Diproses'),
(162, 89, '2025-02-18', 4408109.10, 'Baru'),
(163, 68, '2025-01-20', 2652796.25, 'Diproses'),
(164, 25, '2025-03-19', 4605242.06, 'Diproses'),
(165, 66, '2025-02-26', 806189.91, 'Dibatalkan'),
(166, 26, '2025-01-24', 3263104.02, 'Baru'),
(167, 86, '2025-01-27', 3120235.12, 'Selesai'),
(168, 62, '2025-05-16', 4497868.80, 'Dibatalkan'),
(169, 69, '2025-07-29', 3285743.19, 'Baru'),
(170, 14, '2025-08-01', 388682.69, 'Selesai'),
(171, 25, '2025-08-06', 159762.14, 'Diproses'),
(172, 62, '2025-09-29', 753042.64, 'Selesai'),
(173, 11, '2025-04-10', 4588864.94, 'Dibatalkan'),
(174, 22, '2025-10-20', 4145336.21, 'Selesai'),
(175, 86, '2025-01-12', 228170.15, 'Diproses'),
(176, 14, '2025-10-05', 4072578.26, 'Diproses'),
(177, 43, '2025-06-29', 2998625.18, 'Selesai'),
(178, 82, '2025-07-12', 4283106.06, 'Dibatalkan'),
(179, 98, '2025-01-20', 3622242.43, 'Dibatalkan'),
(180, 61, '2025-10-10', 4349601.65, 'Selesai'),
(181, 8, '2025-10-06', 4289595.05, 'Baru'),
(182, 11, '2025-05-08', 320018.90, 'Diproses'),
(183, 85, '2025-10-13', 752560.63, 'Diproses'),
(184, 19, '2025-10-30', 2321591.78, 'Dibatalkan'),
(185, 87, '2025-01-23', 4569252.47, 'Baru'),
(186, 44, '2025-10-24', 1919454.43, 'Selesai'),
(187, 70, '2025-08-16', 2374880.94, 'Baru'),
(188, 69, '2025-05-09', 2700714.90, 'Diproses'),
(189, 67, '2025-03-15', 3306756.51, 'Selesai'),
(190, 91, '2025-06-28', 1923054.63, 'Dibatalkan'),
(191, 22, '2025-07-11', 1862372.54, 'Baru'),
(192, 65, '2025-11-22', 2557223.81, 'Selesai'),
(193, 36, '2025-08-19', 1126113.23, 'Baru'),
(194, 15, '2025-12-12', 3863475.63, 'Diproses'),
(195, 76, '2025-05-31', 2954017.52, 'Selesai'),
(196, 70, '2025-08-19', 4951084.04, 'Selesai'),
(197, 61, '2025-08-16', 602263.84, 'Baru'),
(198, 67, '2025-01-27', 1414663.53, 'Selesai'),
(199, 15, '2025-11-03', 1883478.42, 'Baru'),
(200, 54, '2025-09-20', 669213.10, 'Diproses'),
(201, 14, '2025-11-28', NULL, NULL),
(202, 9, '2025-12-21', 50000.00, 'BELUM_LUNAS'),
(203, 9, '2025-12-21', 50000.00, 'BELUM_LUNAS'),
(204, 9, '2025-12-21', 50000.00, 'BELUM_LUNAS'),
(205, 9, '2025-12-21', 50000.00, 'BELUM_LUNAS'),
(206, 9, '2025-12-21', 50000.00, 'LUNAS'),
(207, 9, '2025-12-21', 50000.00, 'LUNAS');

-- --------------------------------------------------------

--
-- Struktur dari tabel `produk`
--

CREATE TABLE `produk` (
  `produk_id` int(11) NOT NULL,
  `id_jenis_produk` int(11) DEFAULT NULL,
  `gudang_id` int(11) DEFAULT NULL,
  `nama_produk` varchar(100) DEFAULT NULL,
  `harga_satuan` decimal(12,2) DEFAULT NULL,
  `stok` int(11) DEFAULT NULL,
  `kategori` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `produk`
--

INSERT INTO `produk` (`produk_id`, `id_jenis_produk`, `gudang_id`, `nama_produk`, `harga_satuan`, `stok`, `kategori`) VALUES
(0, 0, 0, 'nama_produk', 0.00, 0, 'kategori'),
(1, 9, 84, 'Tahu', 127325.39, 76, 'makanan'),
(2, 50, 75, 'Kacang Hijau', 309896.33, 60, 'makanan'),
(3, 94, 99, 'Tomat', 282124.67, 15, 'makanan'),
(4, 52, 69, 'Panci', 20427.85, 9, 'peralatan'),
(5, 27, 67, 'Smoothie Berry', 173549.28, 42, 'minuman'),
(6, 16, 93, 'Spatula Kayu', 72649.30, 81, 'peralatan'),
(7, 93, 29, 'Mixer', 340049.92, 72, 'peralatan'),
(8, 39, 72, 'Meja Kayu', 384438.46, 2, 'peralatan'),
(9, 67, 83, 'Telur', 322737.02, 37, 'makanan'),
(10, 7, 96, 'Panci', 25684.00, 46, 'peralatan'),
(11, 99, 43, 'Sayur Bayam', 138015.89, 9, 'makanan'),
(12, 56, 56, 'Sayur Bayam', 83975.35, 78, 'makanan'),
(13, 99, 25, 'Jus Jeruk Segar', 472225.91, 87, 'minuman'),
(14, 76, 12, 'Wajan', 335996.81, 99, 'peralatan'),
(15, 40, 16, 'Saringan Kopi', 142875.46, 14, 'peralatan'),
(16, 16, 29, 'Saringan Kopi', 375372.83, 43, 'peralatan'),
(17, 34, 67, 'Sayur Bayam', 393495.36, 74, 'makanan'),
(18, 42, 46, 'Teko Kopi', 434468.22, 34, 'peralatan'),
(19, 30, 65, 'Wajan', 128384.08, 29, 'peralatan'),
(20, 33, 25, 'Telur', 221911.79, 97, 'makanan'),
(21, 30, 95, 'Smoothie Berry', 211804.33, 2, 'minuman'),
(22, 55, 62, 'Kompor Gas', 396405.80, 71, 'peralatan'),
(23, 16, 53, 'Meja Kayu', 475557.69, 50, 'peralatan'),
(24, 49, 69, 'Smoothie Berry', 125705.84, 19, 'minuman'),
(25, 45, 49, 'Saringan Kopi', 56857.90, 86, 'peralatan'),
(26, 75, 100, 'Blender', 280487.31, 29, 'peralatan'),
(27, 75, 59, 'Spatula Kayu', 327568.84, 76, 'peralatan'),
(28, 82, 82, 'Tempe', 221712.60, 27, 'makanan'),
(29, 99, 25, 'Teh Hijau', 81268.28, 96, 'minuman'),
(30, 52, 99, 'Tahu', 236008.31, 44, 'makanan'),
(31, 89, 33, 'Pisang', 127918.62, 57, 'makanan'),
(32, 1, 7, 'Jus Jeruk Segar', 93498.63, 86, 'minuman'),
(33, 2, 82, 'Jus Jeruk Segar', 425003.81, 45, 'minuman'),
(34, 39, 16, 'Mixer', 218825.77, 83, 'peralatan'),
(35, 81, 85, 'Blender', 13531.14, 42, 'peralatan'),
(36, 9, 50, 'Telur', 485956.24, 23, 'makanan'),
(37, 78, 2, 'Telur', 142581.03, 82, 'makanan'),
(38, 22, 43, 'Jus Jeruk Segar', 109956.84, 62, 'minuman'),
(39, 29, 96, 'Cappuccino', 436862.69, 71, 'minuman'),
(40, 2, 5, 'Meja Kayu', 497055.49, 31, 'peralatan'),
(41, 36, 46, 'Latte Vanila', 40993.13, 93, 'minuman'),
(42, 89, 53, 'Nasi', 474874.72, 32, 'makanan'),
(43, 66, 58, 'Roti Tawar', 374393.47, 88, 'makanan'),
(44, 3, 91, 'Air Mineral', 476716.13, 43, 'minuman'),
(45, 82, 13, 'Pisang', 225630.06, 60, 'makanan'),
(46, 69, 14, 'Tempe', 293102.57, 85, 'makanan'),
(47, 84, 70, 'Roti Tawar', 439656.56, 97, 'makanan'),
(48, 4, 70, 'Wajan', 144746.32, 40, 'peralatan'),
(49, 8, 2, 'Saringan Kopi', 488118.17, 78, 'peralatan'),
(50, 75, 8, 'Cappuccino', 78740.61, 92, 'minuman'),
(51, 47, 99, 'Teh Hijau', 452495.21, 40, 'minuman'),
(52, 87, 74, 'Wajan', 324978.55, 86, 'peralatan'),
(53, 3, 76, 'Tahu', 12314.63, 94, 'makanan'),
(54, 37, 88, 'Kursi Plastik', 33097.20, 87, 'peralatan'),
(55, 7, 35, 'Kopi Tubruk', 462068.53, 97, 'minuman'),
(56, 93, 37, 'Air Mineral', 185033.71, 5, 'minuman'),
(57, 84, 70, 'Tahu', 143553.39, 67, 'makanan'),
(58, 22, 98, 'Tomat', 339506.39, 33, 'makanan'),
(59, 66, 22, 'Kompor Gas', 412106.87, 83, 'peralatan'),
(60, 40, 36, 'Tempe', 187866.99, 87, 'makanan'),
(61, 62, 53, 'Brokoli', 205298.60, 34, 'makanan'),
(62, 23, 68, 'Smoothie Berry', 465537.74, 53, 'minuman'),
(63, 63, 43, 'Meja Kayu', 150473.27, 10, 'peralatan'),
(64, 22, 6, 'Kursi Plastik', 331278.93, 10, 'peralatan'),
(65, 44, 82, 'Pisang', 361504.56, 1, 'makanan'),
(66, 5, 5, 'Saringan Kopi', 307395.48, 100, 'peralatan'),
(67, 60, 56, 'Telur', 177958.65, 78, 'makanan'),
(68, 45, 32, 'Mixer', 423039.78, 55, 'peralatan'),
(69, 45, 74, 'Cappuccino', 156466.54, 33, 'minuman'),
(70, 4, 76, 'Kacang Merah', 24281.94, 33, 'makanan'),
(71, 10, 37, 'Kopi Tubruk', 171018.85, 33, 'minuman'),
(72, 72, 88, 'Saringan Kopi', 169350.21, 96, 'peralatan'),
(73, 49, 51, 'Air Mineral', 29972.29, 28, 'minuman'),
(74, 98, 11, 'Jus Jeruk Segar', 169602.74, 26, 'minuman'),
(75, 3, 55, 'Blender', 82282.73, 18, 'peralatan'),
(76, 59, 82, 'Teh Hijau', 182656.39, 14, 'minuman'),
(77, 39, 60, 'Kentang', 102560.81, 4, 'makanan'),
(78, 79, 67, 'Air Mineral', 475741.17, 62, 'minuman'),
(79, 52, 51, 'Telur', 380691.16, 87, 'makanan'),
(80, 70, 92, 'Tahu', 371287.43, 57, 'makanan'),
(81, 90, 64, 'Air Mineral', 417987.45, 0, 'minuman'),
(82, 68, 91, 'Panci', 438318.61, 18, 'peralatan'),
(83, 60, 1, 'Mixer', 172888.49, 98, 'peralatan'),
(84, 58, 31, 'Pisang', 406013.73, 22, 'makanan'),
(85, 91, 35, 'Matcha Latte', 400035.66, 38, 'minuman'),
(86, 95, 13, 'Sayur Bayam', 201684.70, 13, 'makanan'),
(87, 32, 71, 'Kursi Plastik', 435063.07, 21, 'peralatan'),
(88, 56, 17, 'Kompor Gas', 467096.56, 99, 'peralatan'),
(89, 57, 62, 'Roti Tawar', 274724.94, 32, 'makanan'),
(90, 76, 43, 'Wajan', 18675.52, 85, 'peralatan'),
(91, 64, 53, 'Meja Kayu', 352210.71, 68, 'peralatan'),
(92, 33, 82, 'Meja Kayu', 425600.19, 35, 'peralatan'),
(93, 13, 50, 'Ayam', 214661.10, 3, 'makanan'),
(94, 52, 63, 'Mixer', 196171.12, 9, 'peralatan'),
(95, 20, 75, 'Jus Jeruk Segar', 108564.23, 2, 'minuman'),
(96, 32, 53, 'Kopi Tubruk', 230803.67, 0, 'minuman'),
(97, 74, 22, 'Meja Kayu', 10454.62, 20, 'peralatan'),
(98, 53, 97, 'Kacang Hijau', 308340.61, 33, 'makanan'),
(99, 5, 33, 'Cappuccino', 471271.43, 9, 'minuman'),
(100, 79, 34, 'Blender', 488729.18, 17, 'peralatan');

-- --------------------------------------------------------

--
-- Struktur dari tabel `supplier`
--

CREATE TABLE `supplier` (
  `supplier_id` int(5) NOT NULL,
  `nama` varchar(25) NOT NULL,
  `id_jenis_produk` int(5) NOT NULL,
  `email` varchar(20) NOT NULL,
  `alamat` text NOT NULL,
  `nomor_kontak` int(12) UNSIGNED NOT NULL,
  `jenis_produk` varchar(10) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `supplier`
--

INSERT INTO `supplier` (`supplier_id`, `nama`, `id_jenis_produk`, `email`, `alamat`, `nomor_kontak`, `jenis_produk`) VALUES
(1, 'nama', 0, 'email', 'alamat', 0, 'jenis_prod'),
(2, 'Citra Santoso', 70, 'citra.santoso@suppli', 'Jl. K.H. Wahid Hasyim No.9, Malang', 4294967295, 'minuman'),
(3, 'Andi Wijaya', 71, 'andi.wijaya@supplier', 'Jl. Panglima Polim No.6, Denpasar', 4294967295, 'minuman'),
(4, 'Budi Pratama', 51, 'budi.pratama@supplie', 'Jl. Diponegoro No.8, Semarang', 4294967295, 'minuman'),
(5, 'Eka Pratama', 65, 'eka.pratama@supplier', 'Jl. Diponegoro No.2, Yogyakarta', 4294967295, 'peralatan'),
(6, 'Andi Pratama', 8, 'andi.pratama@supplie', 'Jl. Gajah Mada No.4, Palembang', 4294967295, 'minuman'),
(7, 'Gita Santoso', 48, 'gita.santoso@supplie', 'Jl. Diponegoro No.8, Semarang', 4294967295, 'peralatan'),
(8, 'Fajar Permata', 67, 'fajar.permata@suppli', 'Jl. Merdeka No.1, Jakarta', 4294967295, 'minuman'),
(9, 'Joko Santoso', 63, 'joko.santoso@supplie', 'Jl. Pahlawan No.5, Surabaya', 4294967295, 'minuman'),
(10, 'Eka Permata', 94, 'eka.permata@supplier', 'Jl. K.H. Wahid Hasyim No.9, Malang', 4294967295, 'peralatan'),
(11, 'Hendra Dewi', 64, 'hendra.dewi@supplier', 'Jl. Diponegoro No.8, Semarang', 4294967295, 'makanan'),
(12, 'Budi Wijaya', 24, 'budi.wijaya@supplier', 'Jl. Merdeka No.1, Jakarta', 4294967295, 'peralatan'),
(13, 'Dewi Dewi', 31, 'dewi.dewi@supplierca', 'Jl. Teuku Umar No.3, Makassar', 4294967295, 'minuman'),
(14, 'Hendra Susilo', 71, 'hendra.susilo@suppli', 'Jl. Imam Bonjol No.7, Medan', 4294967295, 'peralatan'),
(15, 'Gita Sari', 61, 'gita.sari@supplierca', 'Jl. Imam Bonjol No.7, Medan', 4294967295, 'minuman'),
(16, 'Joko Pratama', 51, 'joko.pratama@supplie', 'Jl. Diponegoro No.2, Yogyakarta', 4294967295, 'makanan'),
(17, 'Andi Lestari', 9, 'andi.lestari@supplie', 'Jl. Sudirman No.10, Bandung', 4294967295, 'peralatan'),
(18, 'Citra Pratama', 5, 'citra.pratama@suppli', 'Jl. Sudirman No.10, Bandung', 4294967295, 'makanan'),
(19, 'Hendra Putra', 64, 'hendra.putra@supplie', 'Jl. Diponegoro No.2, Yogyakarta', 4294967295, 'makanan'),
(20, 'Intan Gunawan', 50, 'intan.gunawan@suppli', 'Jl. Imam Bonjol No.7, Medan', 4294967295, 'minuman'),
(21, 'Citra Sari', 51, 'citra.sari@supplierc', 'Jl. Sudirman No.10, Bandung', 4294967295, 'makanan'),
(22, 'Dewi Putra', 2, 'dewi.putra@supplierc', 'Jl. Imam Bonjol No.7, Medan', 4294967295, 'peralatan'),
(23, 'Citra Wijaya', 47, 'citra.wijaya@supplie', 'Jl. Teuku Umar No.3, Makassar', 4294967295, 'minuman'),
(24, 'Joko Santoso', 64, 'joko.santoso@supplie', 'Jl. Imam Bonjol No.7, Medan', 4294967295, 'makanan'),
(25, 'Hendra Dewi', 78, 'hendra.dewi@supplier', 'Jl. Merdeka No.1, Jakarta', 4294967295, 'makanan'),
(26, 'Intan Wijaya', 23, 'intan.wijaya@supplie', 'Jl. Diponegoro No.2, Yogyakarta', 4294967295, 'peralatan'),
(27, 'Gita Permata', 21, 'gita.permata@supplie', 'Jl. Gajah Mada No.4, Palembang', 4294967295, 'minuman'),
(28, 'Andi Sari', 39, 'andi.sari@supplierca', 'Jl. Merdeka No.1, Jakarta', 4294967295, 'minuman'),
(29, 'Eka Putra', 98, 'eka.putra@supplierca', 'Jl. Diponegoro No.8, Semarang', 4294967295, 'makanan'),
(30, 'Intan Susilo', 1, 'intan.susilo@supplie', 'Jl. Imam Bonjol No.7, Medan', 4294967295, 'peralatan'),
(31, 'Intan Sari', 34, 'intan.sari@supplierc', 'Jl. Merdeka No.1, Jakarta', 4294967295, 'minuman'),
(32, 'Eka Sari', 58, 'eka.sari@suppliercaf', 'Jl. Merdeka No.1, Jakarta', 4294967295, 'makanan'),
(33, 'Hendra Dewi', 10, 'hendra.dewi@supplier', 'Jl. Diponegoro No.8, Semarang', 4294967295, 'peralatan'),
(34, 'Joko Sari', 22, 'joko.sari@supplierca', 'Jl. Sudirman No.10, Bandung', 4294967295, 'minuman'),
(35, 'Intan Gunawan', 7, 'intan.gunawan@suppli', 'Jl. Teuku Umar No.3, Makassar', 4294967295, 'minuman'),
(36, 'Intan Wijaya', 92, 'intan.wijaya@supplie', 'Jl. Gajah Mada No.4, Palembang', 4294967295, 'peralatan'),
(37, 'Hendra Permata', 5, 'hendra.permata@suppl', 'Jl. Imam Bonjol No.7, Medan', 4294967295, 'minuman'),
(38, 'Joko Wijaya', 49, 'joko.wijaya@supplier', 'Jl. Diponegoro No.8, Semarang', 4294967295, 'makanan'),
(39, 'Citra Lestari', 40, 'citra.lestari@suppli', 'Jl. Diponegoro No.2, Yogyakarta', 4294967295, 'peralatan'),
(40, 'Hendra Putra', 54, 'hendra.putra@supplie', 'Jl. Diponegoro No.2, Yogyakarta', 4294967295, 'makanan'),
(41, 'Fajar Lestari', 29, 'fajar.lestari@suppli', 'Jl. Gajah Mada No.4, Palembang', 4294967295, 'makanan'),
(42, 'Joko Putra', 75, 'joko.putra@supplierc', 'Jl. Diponegoro No.8, Semarang', 4294967295, 'makanan'),
(43, 'Budi Putra', 100, 'budi.putra@supplierc', 'Jl. Pahlawan No.5, Surabaya', 4294967295, 'minuman'),
(44, 'Andi Pratama', 24, 'andi.pratama@supplie', 'Jl. Sudirman No.10, Bandung', 4294967295, 'peralatan'),
(45, 'Fajar Gunawan', 79, 'fajar.gunawan@suppli', 'Jl. Gajah Mada No.4, Palembang', 4294967295, 'makanan'),
(46, 'Intan Wijaya', 82, 'intan.wijaya@supplie', 'Jl. Merdeka No.1, Jakarta', 4294967295, 'minuman'),
(47, 'Dewi Gunawan', 57, 'dewi.gunawan@supplie', 'Jl. K.H. Wahid Hasyim No.9, Malang', 4294967295, 'makanan'),
(48, 'Andi Gunawan', 76, 'andi.gunawan@supplie', 'Jl. Panglima Polim No.6, Denpasar', 4294967295, 'makanan'),
(49, 'Hendra Wijaya', 87, 'hendra.wijaya@suppli', 'Jl. K.H. Wahid Hasyim No.9, Malang', 4294967295, 'minuman'),
(50, 'Budi Lestari', 25, 'budi.lestari@supplie', 'Jl. Diponegoro No.8, Semarang', 4294967295, 'minuman'),
(51, 'Eka Sari', 72, 'eka.sari@suppliercaf', 'Jl. Sudirman No.10, Bandung', 4294967295, 'peralatan'),
(52, 'Fajar Sari', 17, 'fajar.sari@supplierc', 'Jl. Imam Bonjol No.7, Medan', 4294967295, 'minuman'),
(53, 'Budi Sari', 11, 'budi.sari@supplierca', 'Jl. Sudirman No.10, Bandung', 4294967295, 'minuman'),
(54, 'Hendra Dewi', 38, 'hendra.dewi@supplier', 'Jl. K.H. Wahid Hasyim No.9, Malang', 4294967295, 'makanan'),
(55, 'Citra Gunawan', 63, 'citra.gunawan@suppli', 'Jl. Imam Bonjol No.7, Medan', 4294967295, 'minuman'),
(56, 'Eka Gunawan', 77, 'eka.gunawan@supplier', 'Jl. Teuku Umar No.3, Makassar', 4294967295, 'makanan'),
(57, 'Joko Dewi', 61, 'joko.dewi@supplierca', 'Jl. Diponegoro No.8, Semarang', 4294967295, 'minuman'),
(58, 'Citra Pratama', 55, 'citra.pratama@suppli', 'Jl. K.H. Wahid Hasyim No.9, Malang', 4294967295, 'minuman'),
(59, 'Eka Susilo', 43, 'eka.susilo@supplierc', 'Jl. Imam Bonjol No.7, Medan', 4294967295, 'makanan'),
(60, 'Citra Susilo', 26, 'citra.susilo@supplie', 'Jl. Teuku Umar No.3, Makassar', 4294967295, 'makanan'),
(61, 'Gita Dewi', 18, 'gita.dewi@supplierca', 'Jl. Diponegoro No.8, Semarang', 4294967295, 'minuman'),
(62, 'Joko Dewi', 15, 'joko.dewi@supplierca', 'Jl. Imam Bonjol No.7, Medan', 4294967295, 'peralatan'),
(63, 'Andi Sari', 7, 'andi.sari@supplierca', 'Jl. Merdeka No.1, Jakarta', 4294967295, 'peralatan'),
(64, 'Fajar Permata', 58, 'fajar.permata@suppli', 'Jl. Sudirman No.10, Bandung', 4294967295, 'peralatan'),
(65, 'Joko Susilo', 59, 'joko.susilo@supplier', 'Jl. Panglima Polim No.6, Denpasar', 4294967295, 'peralatan'),
(66, 'Hendra Dewi', 57, 'hendra.dewi@supplier', 'Jl. Pahlawan No.5, Surabaya', 4294967295, 'peralatan'),
(67, 'Joko Dewi', 44, 'joko.dewi@supplierca', 'Jl. Panglima Polim No.6, Denpasar', 4294967295, 'minuman'),
(68, 'Gita Dewi', 73, 'gita.dewi@supplierca', 'Jl. Sudirman No.10, Bandung', 4294967295, 'makanan'),
(69, 'Gita Pratama', 50, 'gita.pratama@supplie', 'Jl. Merdeka No.1, Jakarta', 4294967295, 'makanan'),
(70, 'Budi Wijaya', 16, 'budi.wijaya@supplier', 'Jl. Teuku Umar No.3, Makassar', 4294967295, 'makanan'),
(71, 'Hendra Sari', 58, 'hendra.sari@supplier', 'Jl. Pahlawan No.5, Surabaya', 4294967295, 'minuman'),
(72, 'Dewi Susilo', 18, 'dewi.susilo@supplier', 'Jl. Teuku Umar No.3, Makassar', 4294967295, 'peralatan'),
(73, 'Dewi Gunawan', 11, 'dewi.gunawan@supplie', 'Jl. Sudirman No.10, Bandung', 4294967295, 'makanan'),
(74, 'Hendra Dewi', 49, 'hendra.dewi@supplier', 'Jl. Diponegoro No.8, Semarang', 4294967295, 'minuman'),
(75, 'Fajar Gunawan', 29, 'fajar.gunawan@suppli', 'Jl. K.H. Wahid Hasyim No.9, Malang', 4294967295, 'makanan'),
(76, 'Joko Dewi', 80, 'joko.dewi@supplierca', 'Jl. Pahlawan No.5, Surabaya', 4294967295, 'makanan'),
(77, 'Budi Santoso', 40, 'budi.santoso@supplie', 'Jl. Merdeka No.1, Jakarta', 4294967295, 'minuman'),
(78, 'Hendra Sari', 99, 'hendra.sari@supplier', 'Jl. Panglima Polim No.6, Denpasar', 4294967295, 'peralatan'),
(79, 'Fajar Dewi', 99, 'fajar.dewi@supplierc', 'Jl. Diponegoro No.8, Semarang', 4294967295, 'peralatan'),
(80, 'Gita Dewi', 8, 'gita.dewi@supplierca', 'Jl. Panglima Polim No.6, Denpasar', 4294967295, 'peralatan'),
(81, 'Dewi Susilo', 64, 'dewi.susilo@supplier', 'Jl. Gajah Mada No.4, Palembang', 4294967295, 'minuman'),
(82, 'Hendra Susilo', 69, 'hendra.susilo@suppli', 'Jl. Sudirman No.10, Bandung', 4294967295, 'minuman'),
(83, 'Dewi Wijaya', 91, 'dewi.wijaya@supplier', 'Jl. Teuku Umar No.3, Makassar', 4294967295, 'makanan'),
(84, 'Andi Putra', 44, 'andi.putra@supplierc', 'Jl. Imam Bonjol No.7, Medan', 4294967295, 'peralatan'),
(85, 'Hendra Sari', 64, 'hendra.sari@supplier', 'Jl. Diponegoro No.8, Semarang', 4294967295, 'minuman'),
(86, 'Joko Lestari', 68, 'joko.lestari@supplie', 'Jl. Merdeka No.1, Jakarta', 4294967295, 'minuman'),
(87, 'Eka Santoso', 60, 'eka.santoso@supplier', 'Jl. Panglima Polim No.6, Denpasar', 4294967295, 'makanan'),
(88, 'Gita Pratama', 79, 'gita.pratama@supplie', 'Jl. Sudirman No.10, Bandung', 4294967295, 'makanan'),
(89, 'Fajar Pratama', 95, 'fajar.pratama@suppli', 'Jl. Pahlawan No.5, Surabaya', 4294967295, 'peralatan'),
(90, 'Intan Gunawan', 82, 'intan.gunawan@suppli', 'Jl. Diponegoro No.8, Semarang', 4294967295, 'peralatan'),
(91, 'Budi Susilo', 44, 'budi.susilo@supplier', 'Jl. Diponegoro No.8, Semarang', 4294967295, 'makanan'),
(92, 'Fajar Santoso', 35, 'fajar.santoso@suppli', 'Jl. Imam Bonjol No.7, Medan', 4294967295, 'makanan'),
(93, 'Dewi Susilo', 30, 'dewi.susilo@supplier', 'Jl. Pahlawan No.5, Surabaya', 4294967295, 'minuman'),
(94, 'Budi Sari', 25, 'budi.sari@supplierca', 'Jl. K.H. Wahid Hasyim No.9, Malang', 4294967295, 'minuman'),
(95, 'Hendra Gunawan', 11, 'hendra.gunawan@suppl', 'Jl. K.H. Wahid Hasyim No.9, Malang', 4294967295, 'minuman'),
(96, 'Eka Lestari', 88, 'eka.lestari@supplier', 'Jl. Diponegoro No.8, Semarang', 4294967295, 'minuman'),
(97, 'Budi Gunawan', 82, 'budi.gunawan@supplie', 'Jl. Diponegoro No.2, Yogyakarta', 4294967295, 'minuman'),
(98, 'Andi Santoso', 59, 'andi.santoso@supplie', 'Jl. Gajah Mada No.4, Palembang', 4294967295, 'peralatan'),
(99, 'Dewi Permata', 5, 'dewi.permata@supplie', 'Jl. Pahlawan No.5, Surabaya', 4294967295, 'minuman'),
(100, 'Gita Susilo', 92, 'gita.susilo@supplier', 'Jl. Diponegoro No.8, Semarang', 4294967295, 'peralatan');

-- --------------------------------------------------------

--
-- Struktur dari tabel `tetap`
--

CREATE TABLE `tetap` (
  `karyawan_id` int(11) NOT NULL,
  `jam_kerja` varchar(50) DEFAULT NULL,
  `tanggal_masuk` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `tetap`
--

INSERT INTO `tetap` (`karyawan_id`, `jam_kerja`, `tanggal_masuk`) VALUES
(0, 'jam_kerja', '0000-00-00'),
(1, '12:00-20:00', '2024-02-26'),
(2, '09:00-17:00', '2023-01-08'),
(3, '12:00-20:00', '2022-07-22'),
(4, '10:00-18:00', '2024-03-10'),
(5, '09:00-17:00', '2020-05-17'),
(6, '12:00-20:00', '2021-04-02'),
(7, '10:00-18:00', '2020-11-07'),
(8, '08:00-16:00', '2022-12-20'),
(9, '08:00-16:00', '2023-05-09'),
(10, '09:00-17:00', '2024-06-20'),
(11, '09:00-17:00', '2023-05-29'),
(12, '09:00-17:00', '2024-04-27'),
(13, '09:00-17:00', '2022-12-29'),
(14, '08:00-16:00', '2023-07-06'),
(15, '08:00-16:00', '2020-10-28'),
(16, '09:00-17:00', '2024-02-12'),
(17, '10:00-18:00', '2020-04-09'),
(18, '10:00-18:00', '2021-02-23'),
(19, '08:00-16:00', '2024-04-26'),
(20, '12:00-20:00', '2024-06-16'),
(21, '10:00-18:00', '2020-04-02'),
(22, '12:00-20:00', '2025-04-15'),
(23, '08:00-16:00', '2024-05-17'),
(24, '09:00-17:00', '2022-05-01'),
(25, '10:00-18:00', '2024-06-22'),
(26, '08:00-16:00', '2023-01-31'),
(27, '09:00-17:00', '2022-12-21'),
(28, '10:00-18:00', '2020-04-20'),
(29, '09:00-17:00', '2022-02-17'),
(30, '10:00-18:00', '2024-12-16'),
(31, '10:00-18:00', '2024-08-08'),
(32, '08:00-16:00', '2021-06-30'),
(33, '12:00-20:00', '2023-09-12'),
(34, '08:00-16:00', '2023-07-27'),
(35, '10:00-18:00', '2023-12-07'),
(36, '09:00-17:00', '2025-05-04'),
(37, '09:00-17:00', '2020-11-22'),
(38, '08:00-16:00', '2024-02-12'),
(39, '08:00-16:00', '2023-07-11'),
(40, '09:00-17:00', '2021-04-08'),
(41, '10:00-18:00', '2021-11-03'),
(42, '12:00-20:00', '2023-11-20'),
(43, '10:00-18:00', '2021-11-16'),
(44, '10:00-18:00', '2021-11-19'),
(45, '12:00-20:00', '2024-02-21'),
(46, '08:00-16:00', '2020-03-29'),
(47, '10:00-18:00', '2020-07-15'),
(48, '10:00-18:00', '2022-12-17'),
(49, '12:00-20:00', '2020-09-12'),
(50, '12:00-20:00', '2024-04-12'),
(51, '09:00-17:00', '2025-05-04'),
(52, '08:00-16:00', '2024-10-26'),
(53, '12:00-20:00', '2022-02-08'),
(54, '08:00-16:00', '2021-03-03'),
(55, '10:00-18:00', '2024-06-28'),
(56, '09:00-17:00', '2025-02-04'),
(57, '10:00-18:00', '2024-02-16'),
(58, '12:00-20:00', '2025-03-10'),
(59, '12:00-20:00', '2021-04-29'),
(60, '10:00-18:00', '2020-11-29'),
(61, '12:00-20:00', '2022-06-23'),
(62, '10:00-18:00', '2022-11-19'),
(63, '08:00-16:00', '2023-10-08'),
(64, '12:00-20:00', '2021-09-24'),
(65, '12:00-20:00', '2023-06-19'),
(66, '10:00-18:00', '2022-03-02'),
(67, '08:00-16:00', '2020-02-28'),
(68, '09:00-17:00', '2020-01-13'),
(69, '12:00-20:00', '2023-07-15'),
(70, '12:00-20:00', '2022-07-06'),
(71, '12:00-20:00', '2024-05-24'),
(72, '10:00-18:00', '2021-09-01'),
(73, '10:00-18:00', '2025-04-27'),
(74, '09:00-17:00', '2022-01-16'),
(75, '12:00-20:00', '2020-11-08'),
(76, '12:00-20:00', '2024-11-25'),
(77, '10:00-18:00', '2024-09-30'),
(78, '08:00-16:00', '2020-11-06'),
(79, '12:00-20:00', '2023-06-15'),
(80, '09:00-17:00', '2023-01-28'),
(81, '12:00-20:00', '2024-10-15'),
(82, '10:00-18:00', '2020-08-17'),
(83, '09:00-17:00', '2025-01-31'),
(84, '08:00-16:00', '2020-07-06'),
(85, '09:00-17:00', '2021-07-16'),
(86, '09:00-17:00', '2021-01-04'),
(87, '10:00-18:00', '2022-07-16'),
(88, '12:00-20:00', '2021-12-27'),
(89, '10:00-18:00', '2023-06-18'),
(90, '09:00-17:00', '2020-04-21'),
(91, '10:00-18:00', '2020-01-22'),
(92, '09:00-17:00', '2020-10-14'),
(93, '12:00-20:00', '2021-08-24'),
(94, '09:00-17:00', '2025-01-31'),
(95, '09:00-17:00', '2020-08-06'),
(96, '10:00-18:00', '2021-06-06'),
(97, '10:00-18:00', '2025-03-09'),
(98, '09:00-17:00', '2021-09-22'),
(99, '08:00-16:00', '2022-01-30'),
(100, '08:00-16:00', '2020-02-07');

-- --------------------------------------------------------

--
-- Struktur dari tabel `tunai`
--

CREATE TABLE `tunai` (
  `pembayaran_id` int(11) NOT NULL,
  `uang_diterima` decimal(12,2) DEFAULT NULL,
  `uang_kembalian` decimal(12,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `tunai`
--

INSERT INTO `tunai` (`pembayaran_id`, `uang_diterima`, `uang_kembalian`) VALUES
(1, 526478.00, 459253.00),
(2, 730822.00, 173819.00),
(3, 277158.00, 91261.00),
(4, 604497.00, 226838.00),
(5, 112836.00, 88635.00),
(6, 334904.00, 233210.00),
(7, 806913.00, 323320.00),
(8, 585093.00, 170331.00),
(9, 119985.00, 19420.00),
(10, 616080.00, 155886.00),
(11, 177099.00, 36810.00),
(12, 580296.00, 568797.00),
(13, 35406.00, 14570.00),
(14, 258700.00, 88696.00),
(15, 658204.00, 530706.00),
(16, 999398.00, 331448.00),
(17, 159633.00, 36792.00),
(18, 20979.00, 16779.00),
(19, 451253.00, 216339.00),
(20, 711926.00, 704119.00),
(21, 406425.00, 16080.00),
(22, 416840.00, 374833.00),
(23, 133839.00, 26984.00),
(24, 890269.00, 870458.00),
(25, 930993.00, 380621.00),
(26, 193005.00, 93676.00),
(27, 65290.00, 18614.00),
(28, 760002.00, 613672.00),
(29, 619028.00, 471680.00),
(30, 559706.00, 117176.00),
(31, 307104.00, 257775.00),
(32, 964629.00, 207860.00),
(33, 679208.00, 678291.00),
(34, 809646.00, 319016.00),
(35, 817300.00, 60923.00),
(36, 829528.00, 92096.00),
(37, 46865.00, 5101.00),
(38, 885739.00, 441452.00),
(39, 226435.00, 223437.00),
(40, 881879.00, 687351.00),
(41, 150914.00, 125327.00),
(42, 448512.00, 112116.00),
(43, 344894.00, 94438.00),
(44, 555730.00, 491933.00),
(45, 835778.00, 119138.00),
(46, 812365.00, 347502.00),
(47, 425379.00, 35498.00),
(48, 430146.00, 395952.00),
(49, 46049.00, 24866.00),
(50, 83872.00, 50148.00),
(51, 331194.00, 5944.00),
(52, 17792.00, 5789.00),
(53, 500439.00, 217947.00),
(54, 690864.00, 224978.00),
(55, 578740.00, 527233.00),
(56, 826998.00, 732012.00),
(57, 193895.00, 136566.00),
(58, 737201.00, 88055.00),
(59, 646908.00, 398294.00),
(60, 323042.00, 170453.00),
(61, 762480.00, 621200.00),
(62, 184009.00, 111445.00),
(63, 658659.00, 555735.00),
(64, 410637.00, 350960.00),
(65, 545902.00, 379689.00),
(66, 504658.00, 117862.00),
(67, 639964.00, 275504.00),
(68, 706297.00, 603056.00),
(69, 266469.00, 181109.00),
(70, 587779.00, 417814.00),
(71, 185901.00, 14051.00),
(72, 973774.00, 572742.00),
(73, 212977.00, 92632.00),
(74, 781608.00, 106280.00),
(75, 347361.00, 281514.00),
(76, 124688.00, 4129.00),
(77, 307583.00, 49850.00),
(78, 983091.00, 547286.00),
(79, 392178.00, 308823.00),
(80, 213325.00, 112548.00),
(81, 261106.00, 62760.00),
(82, 970043.00, 883384.00),
(83, 294273.00, 56594.00),
(84, 132452.00, 74795.00),
(85, 394136.00, 17953.00),
(86, 329446.00, 133241.00),
(87, 424739.00, 379733.00),
(88, 22593.00, 3545.00),
(89, 139922.00, 35761.00),
(90, 619543.00, 564529.00),
(91, 576520.00, 70458.00),
(92, 522298.00, 439113.00),
(93, 743559.00, 248771.00),
(94, 311892.00, 253266.00),
(95, 217331.00, 189194.00),
(96, 824147.00, 43745.00),
(97, 219181.00, 116410.00),
(98, 22578.00, 21386.00),
(99, 570270.00, 434699.00),
(100, 367318.00, 318287.00),
(101, 615695.47, 497230.15),
(102, 675359.33, 500459.83),
(103, 619404.11, 611050.14),
(104, 261508.98, 79992.67),
(105, 660888.72, 496263.80),
(106, 941632.76, 456226.83),
(107, 138747.63, 86586.97),
(108, 50351.51, 43038.52),
(109, 619494.13, 604310.86),
(110, 47581.13, 46488.51),
(111, 143104.17, 105810.55),
(112, 226800.47, 105931.13),
(113, 458055.86, 372794.41),
(114, 276256.86, 99877.80),
(115, 40863.07, 21671.40),
(116, 709116.57, 587908.46),
(117, 799009.03, 533099.39),
(118, 499035.44, 486175.05),
(119, 199893.29, 101237.31),
(120, 304418.12, 188572.58),
(121, 98887.61, 3125.84),
(122, 768167.35, 734288.61),
(123, 527105.79, 18822.87),
(124, 375863.07, 353141.13),
(125, 539605.82, 30212.54),
(126, 39747.44, 39660.92),
(127, 711330.72, 252256.95),
(128, 672204.23, 242822.78),
(129, 843755.45, 355395.81),
(130, 702819.01, 469742.64),
(131, 729257.10, 648182.10),
(132, 313625.65, 306373.61),
(133, 466061.32, 413696.51),
(134, 167897.71, 97703.29),
(135, 48878.82, 38388.63),
(136, 692013.02, 682695.40),
(137, 695252.46, 450184.58),
(138, 634724.56, 629419.62),
(139, 592560.15, 473441.56),
(140, 152387.62, 97402.74),
(141, 723831.56, 261959.79),
(142, 548486.23, 470801.22),
(143, 958990.93, 245090.27),
(144, 717681.18, 326750.34),
(145, 860755.58, 228635.49),
(146, 664519.99, 407471.35),
(147, 173544.32, 129037.14),
(148, 741661.14, 432832.34),
(149, 575848.63, 95912.41),
(150, 262997.41, 200933.75),
(151, 69263.60, 39248.53),
(152, 960036.46, 618197.63),
(153, 743157.61, 680144.09),
(154, 81652.95, 58700.28),
(155, 138313.26, 9220.04),
(156, 560285.61, 118135.76),
(157, 666034.33, 84051.88),
(158, 368955.25, 51307.35),
(159, 764942.79, 667822.85),
(160, 528253.60, 49886.66),
(161, 64445.76, 23978.28),
(162, 935427.19, 749274.50),
(163, 209883.74, 107137.32),
(164, 717916.26, 258782.93),
(165, 456654.64, 119659.36),
(166, 610019.54, 331394.27),
(167, 883164.29, 328345.11),
(168, 989895.62, 468242.70),
(169, 89530.68, 87156.35),
(170, 957706.12, 156169.18),
(171, 721507.04, 75459.76),
(172, 323515.62, 71411.42),
(173, 336004.35, 326367.05),
(174, 673471.14, 123713.01),
(175, 568690.97, 444438.00),
(176, 623733.63, 79343.97),
(177, 186721.06, 98568.57),
(178, 434045.21, 137525.91),
(179, 525993.75, 243706.76),
(180, 708240.03, 21968.11),
(181, 248806.30, 136079.50),
(182, 981278.25, 294412.20),
(183, 478604.02, 395175.84),
(184, 307903.61, 45431.86),
(185, 797739.18, 497708.03),
(186, 397808.66, 10735.79),
(187, 744189.45, 129538.97),
(188, 352745.61, 22481.61),
(189, 327291.85, 95765.47),
(190, 154622.72, 62391.04),
(191, 132119.96, 14844.23),
(192, 511507.26, 359142.06),
(193, 445749.16, 206707.87),
(194, 390880.41, 279742.56),
(195, 25644.23, 11098.54),
(196, 861168.69, 108596.97),
(197, 645275.22, 325610.55),
(198, 798166.76, 172682.85),
(199, 33734.57, 28274.68),
(200, 676345.09, 560802.77);

--
-- Indexes for dumped tables
--

--
-- Indeks untuk tabel `audit_event_log`
--
ALTER TABLE `audit_event_log`
  ADD PRIMARY KEY (`log_id`);

--
-- Indeks untuk tabel `bah_makanan`
--
ALTER TABLE `bah_makanan`
  ADD PRIMARY KEY (`jenis_makanan`),
  ADD KEY `id_jenis_produk` (`id_jenis_produk`);

--
-- Indeks untuk tabel `detail_pembelian`
--
ALTER TABLE `detail_pembelian`
  ADD PRIMARY KEY (`detail_id`),
  ADD KEY `pembelian_id` (`pembelian_id`),
  ADD KEY `produk_id` (`produk_id`);

--
-- Indeks untuk tabel `detail_pesanan`
--
ALTER TABLE `detail_pesanan`
  ADD PRIMARY KEY (`detail_id`),
  ADD KEY `pesanan_id` (`pesanan_id`),
  ADD KEY `produk_id` (`produk_id`);

--
-- Indeks untuk tabel `gudang`
--
ALTER TABLE `gudang`
  ADD PRIMARY KEY (`gudang_id`);

--
-- Indeks untuk tabel `jenis_produk`
--
ALTER TABLE `jenis_produk`
  ADD PRIMARY KEY (`id_jenis_produk`);

--
-- Indeks untuk tabel `karyawan`
--
ALTER TABLE `karyawan`
  ADD PRIMARY KEY (`karyawan_id`),
  ADD KEY `cariKaryawan` (`karyawan_id`,`nama`,`jabatan`,`nomor_hp`,`email`);

--
-- Indeks untuk tabel `minuman`
--
ALTER TABLE `minuman`
  ADD PRIMARY KEY (`jenis_minuman`),
  ADD KEY `fk_minuman` (`id_jenis_produk`);

--
-- Indeks untuk tabel `non_tunai`
--
ALTER TABLE `non_tunai`
  ADD PRIMARY KEY (`pembayaran_id`);

--
-- Indeks untuk tabel `part_time`
--
ALTER TABLE `part_time`
  ADD PRIMARY KEY (`karyawan_id`);

--
-- Indeks untuk tabel `pelanggan`
--
ALTER TABLE `pelanggan`
  ADD PRIMARY KEY (`pelanggan_id`),
  ADD KEY `IndexPelangganNama` (`nama`);

--
-- Indeks untuk tabel `pembayaran`
--
ALTER TABLE `pembayaran`
  ADD PRIMARY KEY (`pembayaran_id`),
  ADD KEY `fk_karyawan` (`karyawan_id`),
  ADD KEY `pesanan_id` (`pesanan_id`);

--
-- Indeks untuk tabel `pembelian`
--
ALTER TABLE `pembelian`
  ADD PRIMARY KEY (`pembelian_id`),
  ADD KEY `supplier_id` (`supplier_id`),
  ADD KEY `pelanggan_id` (`pelanggan_id`);

--
-- Indeks untuk tabel `peralatan`
--
ALTER TABLE `peralatan`
  ADD PRIMARY KEY (`jenis_peralatan`),
  ADD KEY `fk_peralatan` (`id_jenis_produk`);

--
-- Indeks untuk tabel `pesanan`
--
ALTER TABLE `pesanan`
  ADD PRIMARY KEY (`pesanan_id`),
  ADD KEY `pelanggan_id` (`pelanggan_id`),
  ADD KEY `IndexPesananStatusTanggal` (`status_pesanan`,`tanggal_pesanan`);

--
-- Indeks untuk tabel `produk`
--
ALTER TABLE `produk`
  ADD PRIMARY KEY (`produk_id`),
  ADD KEY `id_jenis_produk` (`id_jenis_produk`),
  ADD KEY `gudang_id` (`gudang_id`),
  ADD KEY `IndexProdukKategoriHarga` (`kategori`,`harga_satuan`);

--
-- Indeks untuk tabel `supplier`
--
ALTER TABLE `supplier`
  ADD PRIMARY KEY (`supplier_id`);

--
-- Indeks untuk tabel `tetap`
--
ALTER TABLE `tetap`
  ADD PRIMARY KEY (`karyawan_id`);

--
-- Indeks untuk tabel `tunai`
--
ALTER TABLE `tunai`
  ADD PRIMARY KEY (`pembayaran_id`);

--
-- AUTO_INCREMENT untuk tabel yang dibuang
--

--
-- AUTO_INCREMENT untuk tabel `audit_event_log`
--
ALTER TABLE `audit_event_log`
  MODIFY `log_id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT untuk tabel `pelanggan`
--
ALTER TABLE `pelanggan`
  MODIFY `pelanggan_id` int(5) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=101;

--
-- AUTO_INCREMENT untuk tabel `pembayaran`
--
ALTER TABLE `pembayaran`
  MODIFY `pembayaran_id` int(5) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=203;

--
-- AUTO_INCREMENT untuk tabel `supplier`
--
ALTER TABLE `supplier`
  MODIFY `supplier_id` int(5) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=101;

--
-- Ketidakleluasaan untuk tabel pelimpahan (Dumped Tables)
--

--
-- Ketidakleluasaan untuk tabel `bah_makanan`
--
ALTER TABLE `bah_makanan`
  ADD CONSTRAINT `bah_makanan_ibfk_1` FOREIGN KEY (`id_jenis_produk`) REFERENCES `jenis_produk` (`id_jenis_produk`);

--
-- Ketidakleluasaan untuk tabel `detail_pembelian`
--
ALTER TABLE `detail_pembelian`
  ADD CONSTRAINT `detail_pembelian_ibfk_1` FOREIGN KEY (`pembelian_id`) REFERENCES `pembelian` (`pembelian_id`),
  ADD CONSTRAINT `detail_pembelian_ibfk_2` FOREIGN KEY (`produk_id`) REFERENCES `produk` (`produk_id`);

--
-- Ketidakleluasaan untuk tabel `detail_pesanan`
--
ALTER TABLE `detail_pesanan`
  ADD CONSTRAINT `detail_pesanan_ibfk_1` FOREIGN KEY (`pesanan_id`) REFERENCES `pesanan` (`pesanan_id`),
  ADD CONSTRAINT `detail_pesanan_ibfk_2` FOREIGN KEY (`produk_id`) REFERENCES `produk` (`produk_id`);

--
-- Ketidakleluasaan untuk tabel `minuman`
--
ALTER TABLE `minuman`
  ADD CONSTRAINT `fk_minuman` FOREIGN KEY (`id_jenis_produk`) REFERENCES `jenis_produk` (`id_jenis_produk`);

--
-- Ketidakleluasaan untuk tabel `non_tunai`
--
ALTER TABLE `non_tunai`
  ADD CONSTRAINT `non_tunai_ibfk_1` FOREIGN KEY (`pembayaran_id`) REFERENCES `pembayaran` (`pembayaran_id`);

--
-- Ketidakleluasaan untuk tabel `part_time`
--
ALTER TABLE `part_time`
  ADD CONSTRAINT `part_time_ibfk_1` FOREIGN KEY (`karyawan_id`) REFERENCES `karyawan` (`karyawan_id`);

--
-- Ketidakleluasaan untuk tabel `pembayaran`
--
ALTER TABLE `pembayaran`
  ADD CONSTRAINT `fk_karyawan` FOREIGN KEY (`karyawan_id`) REFERENCES `karyawan` (`karyawan_id`),
  ADD CONSTRAINT `pembayaran_ibfk_1` FOREIGN KEY (`pesanan_id`) REFERENCES `pesanan` (`pesanan_id`);

--
-- Ketidakleluasaan untuk tabel `pembelian`
--
ALTER TABLE `pembelian`
  ADD CONSTRAINT `pembelian_ibfk_1` FOREIGN KEY (`supplier_id`) REFERENCES `supplier` (`supplier_id`),
  ADD CONSTRAINT `pembelian_ibfk_2` FOREIGN KEY (`pelanggan_id`) REFERENCES `pelanggan` (`pelanggan_id`);

--
-- Ketidakleluasaan untuk tabel `peralatan`
--
ALTER TABLE `peralatan`
  ADD CONSTRAINT `fk_peralatan` FOREIGN KEY (`id_jenis_produk`) REFERENCES `jenis_produk` (`id_jenis_produk`);

--
-- Ketidakleluasaan untuk tabel `pesanan`
--
ALTER TABLE `pesanan`
  ADD CONSTRAINT `pesanan_ibfk_1` FOREIGN KEY (`pelanggan_id`) REFERENCES `pelanggan` (`pelanggan_id`);

--
-- Ketidakleluasaan untuk tabel `produk`
--
ALTER TABLE `produk`
  ADD CONSTRAINT `produk_ibfk_1` FOREIGN KEY (`id_jenis_produk`) REFERENCES `jenis_produk` (`id_jenis_produk`),
  ADD CONSTRAINT `produk_ibfk_2` FOREIGN KEY (`gudang_id`) REFERENCES `gudang` (`gudang_id`);

--
-- Ketidakleluasaan untuk tabel `tetap`
--
ALTER TABLE `tetap`
  ADD CONSTRAINT `tetap_ibfk_1` FOREIGN KEY (`karyawan_id`) REFERENCES `karyawan` (`karyawan_id`);

--
-- Ketidakleluasaan untuk tabel `tunai`
--
ALTER TABLE `tunai`
  ADD CONSTRAINT `tunai_ibfk_1` FOREIGN KEY (`pembayaran_id`) REFERENCES `pembayaran` (`pembayaran_id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
