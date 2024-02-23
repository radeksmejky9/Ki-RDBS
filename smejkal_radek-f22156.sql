-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Jan 15, 2024 at 04:54 PM
-- Server version: 10.4.28-MariaDB
-- PHP Version: 8.2.4

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `smejkal_radek-f22156`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `ProcessUsersWithMultipleReviews` ()   BEGIN
        DECLARE done INT DEFAULT 0;
        DECLARE userId INT;
        DECLARE reviewCount INT;

        DECLARE cur CURSOR FOR
            SELECT id
            FROM uzivatele
            WHERE id IN (
                SELECT id_uzivatel
                FROM recenze
                GROUP BY id_uzivatel
                HAVING COUNT(*) > 1
            );

        DECLARE CONTINUE HANDLER FOR NOT FOUND
            SET done = 1;

        START TRANSACTION;

        CREATE TEMPORARY TABLE IF NOT EXISTS temp_users_multiple_reviews (
            user_id INT,
            review_count INT
        );

        OPEN cur;

        read_loop: LOOP
            FETCH cur INTO userId;

            IF done THEN
                LEAVE read_loop;
            END IF;

            SELECT COUNT(*) INTO reviewCount
            FROM recenze
            WHERE id_uzivatel = userId;

            INSERT INTO temp_users_multiple_reviews (user_id, review_count)
            VALUES (userId, reviewCount);
        END LOOP;

        CLOSE cur;
        COMMIT;
        DROP TABLE IF EXISTS users_multiple_reviews;
        CREATE TABLE users_multiple_reviews (user_id INT, review_count INT);
        INSERT INTO users_multiple_reviews (user_id, review_count)
        SELECT * FROM temp_users_multiple_reviews;
        DROP TEMPORARY TABLE IF EXISTS temp_users_multiple_reviews;


    END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `SELECT_best_monitor` ()   SELECT
  m.id,
  m.nazev AS monitor,
  v.nazev AS vyrobce,
  v.popis AS popis_vyrobce,
  CONCAT(u.velikost, j1.zkratka) AS uhlopricka,
  tp.nazev AS typ_panelu,
  r.nazev AS rozliseni_nazev,
  CONCAT(r.sirka, j2.zkratka) AS rozliseni_sirka,
  CONCAT(r.vyska, j2.zkratka) AS rozliseni_vyska,
  CONCAT(f.hodnota, j3.zkratka) AS frekvence,
  GROUP_CONCAT(DISTINCT k.typ) AS konektory_monitoru,
  GROUP_CONCAT(DISTINCT fu.nazev) AS funkce_monitoru,
  AVG(rn.hodnoceni) AS prumerne_hodnoceni,
  COUNT(DISTINCT rn.id) AS pocet_recenzi
FROM
  monitory m
JOIN
  vyrobci v ON m.id_vyrobce = v.id
JOIN
  uhlopricky u ON m.id_uhlopricka = u.id
JOIN
  typy_panelu tp ON m.id_typ_panelu = tp.id
JOIN
  rozliseni r ON m.id_rozliseni = r.id
JOIN
  frekvence f ON m.id_frekvence = f.id
JOIN
  kon_mon km ON m.id = km.id_mon
JOIN
  konektory k ON km.id_kon = k.id
JOIN
  fun_mon fm ON m.id = fm.id_mon
JOIN
  funkce fu ON fm.id_fun = fu.id
JOIN
  jednotky j1 ON u.id_jednotka = j1.id
JOIN
  jednotky j2 ON r.id_jednotka = j2.id
JOIN
  jednotky j3 ON f.id_jednotka = j3.id
LEFT JOIN
  recenze rn ON m.id = rn.id_monitor
GROUP BY
  m.id
HAVING COUNT(DISTINCT rn.id) > 0
ORDER BY
  AVG(rn.hodnoceni) DESC, COUNT(DISTINCT rn.id)$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `SELECT_by_params` (IN `vyrobce_param` VARCHAR(255), IN `nazev_param` VARCHAR(255), IN `konektor_param` VARCHAR(255), IN `frekvence_param` INT(11))   BEGIN
  SET @where_clause = '';

  IF vyrobce_param != '' THEN
    SET @where_clause = CONCAT(@where_clause, ' AND v.nazev = ', QUOTE(vyrobce_param));
  END IF;

  IF nazev_param != '' THEN
    SET @where_clause = CONCAT(@where_clause, ' AND m.nazev = ', QUOTE(nazev_param));
  END IF;

 IF frekvence_param != '' THEN
    SET @where_clause = CONCAT(@where_clause, ' AND f.hodnota = ', QUOTE(frekvence_param));
  END IF;

  IF konektor_param != '' THEN
    SET @where_clause = CONCAT(@where_clause, ' AND k.typ = ', QUOTE(konektor_param));
  END IF;

  SET @query = CONCAT(
    'SELECT
  m.id,
  m.nazev AS monitor,
  v.nazev AS vyrobce,
  v.popis AS popis_vyrobce,
  CONCAT(u.velikost, j1.zkratka) AS uhlopricka,
  tp.nazev AS typ_panelu,
  r.nazev AS rozliseni_nazev,
  CONCAT(r.sirka, j2.zkratka) AS rozliseni_sirka,
  CONCAT(r.vyska, j2.zkratka) AS rozliseni_vyska,
  CONCAT(f.hodnota, j3.zkratka) AS frekvence,
  GROUP_CONCAT(DISTINCT k.typ) AS konektory_monitoru,
  GROUP_CONCAT(DISTINCT fu.nazev) AS funkce_monitoru,
  AVG(rn.hodnoceni) AS prumerne_hodnoceni,
  COUNT(DISTINCT rn.id) AS pocet_recenzi
FROM
  monitory m
JOIN
  vyrobci v ON m.id_vyrobce = v.id
JOIN
  uhlopricky u ON m.id_uhlopricka = u.id
JOIN
  typy_panelu tp ON m.id_typ_panelu = tp.id
JOIN
  rozliseni r ON m.id_rozliseni = r.id
JOIN
  frekvence f ON m.id_frekvence = f.id
JOIN
  kon_mon km ON m.id = km.id_mon
JOIN
  konektory k ON km.id_kon = k.id
JOIN
  fun_mon fm ON m.id = fm.id_mon
JOIN
  funkce fu ON fm.id_fun = fu.id
JOIN
  jednotky j1 ON u.id_jednotka = j1.id
JOIN
  jednotky j2 ON r.id_jednotka = j2.id
JOIN
  jednotky j3 ON f.id_jednotka = j3.id
LEFT JOIN
  recenze rn ON m.id = rn.id_monitor
  WHERE 1=1',
    @where_clause,'
GROUP BY
  m.id
ORDER BY
  m.id ASC;
'
  );

  PREPARE stmt FROM @query;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `SELECT_monitor` ()   SELECT
  m.id,
  m.nazev AS monitor,
  v.nazev AS vyrobce,
  v.popis AS popis_vyrobce,
  CONCAT(u.velikost, j1.zkratka) AS uhlopricka,
  tp.nazev AS typ_panelu,
  r.nazev AS rozliseni_nazev,
  CONCAT(r.sirka, j2.zkratka) AS rozliseni_sirka,
  CONCAT(r.vyska, j2.zkratka) AS rozliseni_vyska,
  CONCAT(f.hodnota, j3.zkratka) AS frekvence,
  GROUP_CONCAT(DISTINCT k.typ) AS konektory_monitoru,
  GROUP_CONCAT(DISTINCT fu.nazev) AS funkce_monitoru,
  AVG(rn.hodnoceni) AS prumerne_hodnoceni,
  COUNT(DISTINCT rn.id) AS pocet_recenzi
FROM
  monitory m
JOIN
  vyrobci v ON m.id_vyrobce = v.id
JOIN
  uhlopricky u ON m.id_uhlopricka = u.id
JOIN
  typy_panelu tp ON m.id_typ_panelu = tp.id
JOIN
  rozliseni r ON m.id_rozliseni = r.id
JOIN
  frekvence f ON m.id_frekvence = f.id
JOIN
  kon_mon km ON m.id = km.id_mon
JOIN
  konektory k ON km.id_kon = k.id
JOIN
  fun_mon fm ON m.id = fm.id_mon
JOIN
  funkce fu ON fm.id_fun = fu.id
JOIN
  jednotky j1 ON u.id_jednotka = j1.id
JOIN
  jednotky j2 ON r.id_jednotka = j2.id
JOIN
  jednotky j3 ON f.id_jednotka = j3.id
LEFT JOIN
  recenze rn ON m.id = rn.id_monitor
GROUP BY
  m.id
HAVING COUNT(DISTINCT rn.id) > 0
ORDER BY
  m.id ASC$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `SELECT_recenze` ()   SELECT u.jmeno AS uzivatel_jmeno, m.nazev AS monitor, v.nazev AS vyrobce, r.text AS textove_hodnoceni, r.hodnoceni AS hodnoceni
FROM Recenze r
JOIN Uzivatele u ON r.id_uzivatel = u.id
JOIN Monitory m ON r.id_monitor = m.id
JOIN Vyrobci v ON m.id_vyrobce = v.id
GROUP BY r.id$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `SELECT_row_count` ()   SELECT 
    SUM(row_count) AS celkovy_pocet, 
    AVG(row_count) AS prumerny_pocet 
FROM (
    SELECT 'frekvence', COUNT(*) AS row_count FROM frekvence
    UNION ALL
    SELECT 'funkce', COUNT(*) AS row_count FROM funkce
    UNION ALL
    SELECT 'fun_mon', COUNT(*) AS row_count FROM fun_mon
    UNION ALL
    SELECT 'jednotky', COUNT(*) AS row_count FROM jednotky
    UNION ALL
    SELECT 'konektory', COUNT(*) AS row_count FROM konektory
    UNION ALL
    SELECT 'kon_mon', COUNT(*) AS row_count FROM kon_mon
    UNION ALL
    SELECT 'monitory', COUNT(*) AS row_count FROM monitory
    UNION ALL
    SELECT 'recenze', COUNT(*) AS row_count FROM recenze
    UNION ALL
    SELECT 'rozliseni', COUNT(*) AS row_count FROM rozliseni
    UNION ALL
    SELECT 'typy_panelu', COUNT(*) AS row_count FROM typy_panelu
    UNION ALL
    SELECT 'uhlopricky', COUNT(*) AS row_count FROM uhlopricky
    UNION ALL
    SELECT 'uzivatele', COUNT(*) AS row_count FROM uzivatele
    UNION ALL
    SELECT 'vyrobci', COUNT(*) AS row_count FROM vyrobci
    UNION ALL
    SELECT 'kat_mon', COUNT(*) AS row_count FROM kat_mon
    UNION ALL
    SELECT 'kategorie', COUNT(*) AS row_count FROM kategorie
    
    
) AS counts$$

--
-- Functions
--
CREATE DEFINER=`root`@`localhost` FUNCTION `CalculateAverageRatingForMonitor` (`monitorId` INT) RETURNS DECIMAL(3,2)  BEGIN
    DECLARE avgRating DECIMAL(3,2);

    SELECT AVG(hodnoceni) INTO avgRating
    FROM recenze
    WHERE id_monitor = monitorId;

    RETURN avgRating;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `frekvence`
--

CREATE TABLE `frekvence` (
  `id` int(11) NOT NULL,
  `hodnota` int(3) DEFAULT NULL,
  `id_jednotka` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_czech_ci;

--
-- Dumping data for table `frekvence`
--

INSERT INTO `frekvence` (`id`, `hodnota`, `id_jednotka`) VALUES
(1, 60, 3),
(2, 75, 3),
(3, 85, 3),
(4, 100, 3),
(5, 120, 3),
(6, 144, 3),
(7, 165, 3),
(8, 240, 3);

-- --------------------------------------------------------

--
-- Table structure for table `funkce`
--

CREATE TABLE `funkce` (
  `id` int(11) NOT NULL,
  `nazev` varchar(70) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_czech_ci;

--
-- Dumping data for table `funkce`
--

INSERT INTO `funkce` (`id`, `nazev`) VALUES
(1, 'Reproduktory'),
(2, 'Nastavitelná výška'),
(3, 'HDR'),
(4, 'Pivot'),
(5, 'Flicker-free'),
(6, 'Filtr modrého světla'),
(7, 'Podpora 3D'),
(8, 'KVM');

-- --------------------------------------------------------

--
-- Table structure for table `fun_mon`
--

CREATE TABLE `fun_mon` (
  `id_fun` int(11) DEFAULT NULL,
  `id_mon` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_czech_ci;

--
-- Dumping data for table `fun_mon`
--

INSERT INTO `fun_mon` (`id_fun`, `id_mon`) VALUES
(2, 1),
(4, 1),
(5, 1),
(4, 2),
(3, 2),
(5, 2),
(8, 3),
(2, 3),
(6, 3),
(2, 4),
(7, 4),
(6, 4),
(6, 5),
(2, 5),
(3, 5),
(1, 6),
(1, 6),
(8, 6),
(8, 7),
(5, 7),
(2, 7),
(8, 8),
(3, 8),
(8, 8),
(6, 9),
(7, 9),
(8, 9),
(8, 10),
(8, 10),
(8, 10),
(1, 11),
(2, 11),
(6, 11),
(7, 12),
(3, 12),
(7, 12),
(5, 13),
(8, 13),
(1, 13),
(6, 14),
(3, 14),
(3, 14),
(7, 15),
(7, 15),
(1, 15),
(5, 16),
(5, 16),
(3, 16),
(7, 17),
(3, 17),
(1, 17),
(5, 18),
(4, 18),
(6, 18),
(2, 19),
(7, 19),
(6, 19),
(7, 20),
(8, 20),
(2, 20),
(8, 21),
(5, 21),
(7, 21),
(3, 22),
(2, 22),
(1, 22),
(8, 23),
(4, 23),
(2, 23),
(7, 24),
(4, 24),
(8, 24);

-- --------------------------------------------------------

--
-- Table structure for table `jednotky`
--

CREATE TABLE `jednotky` (
  `id` int(11) NOT NULL,
  `nazev` varchar(50) DEFAULT NULL,
  `zkratka` varchar(12) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_czech_ci;

--
-- Dumping data for table `jednotky`
--

INSERT INTO `jednotky` (`id`, `nazev`, `zkratka`) VALUES
(1, 'palce', '\"'),
(2, 'pixely', 'px'),
(3, 'hertz', 'hz');

-- --------------------------------------------------------

--
-- Table structure for table `kategorie`
--

CREATE TABLE `kategorie` (
  `id` int(11) NOT NULL,
  `nazev` varchar(50) DEFAULT NULL,
  `id_nadkategorie` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `kategorie`
--

INSERT INTO `kategorie` (`id`, `nazev`, `id_nadkategorie`) VALUES
(1, 'Všechny monitory', NULL),
(2, 'Herní monitory', 1),
(3, 'Kancelářské monitory', 1),
(4, '4K monitory', 1),
(5, 'Zahnuté monitory', 1),
(6, 'Rozpočtové monitory', 1),
(7, 'High-End monitory', 1);

-- --------------------------------------------------------

--
-- Table structure for table `kat_mon`
--

CREATE TABLE `kat_mon` (
  `id_kat` int(11) DEFAULT NULL,
  `id_mon` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_czech_ci;

--
-- Dumping data for table `kat_mon`
--

INSERT INTO `kat_mon` (`id_kat`, `id_mon`) VALUES
(6, 18),
(3, 3),
(5, 14),
(3, 19),
(7, 23),
(3, 9),
(5, 10),
(7, 15),
(3, 1),
(2, 2),
(5, 4),
(6, 20),
(6, 12),
(3, 21),
(3, 24),
(5, 11),
(7, 5),
(4, 6),
(6, 8),
(6, 13),
(5, 22),
(5, 25),
(3, 7),
(6, 16),
(2, 17);

-- --------------------------------------------------------

--
-- Table structure for table `konektory`
--

CREATE TABLE `konektory` (
  `id` int(11) NOT NULL,
  `typ` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_czech_ci;

--
-- Dumping data for table `konektory`
--

INSERT INTO `konektory` (`id`, `typ`) VALUES
(1, 'HDMI'),
(2, 'VGA'),
(3, 'DP'),
(4, 'USB-C'),
(5, 'AV'),
(6, 'DVI'),
(7, 'SDI'),
(8, 'NDI'),
(9, 'miniDP'),
(10, 'Thunderbolt');

-- --------------------------------------------------------

--
-- Table structure for table `kon_mon`
--

CREATE TABLE `kon_mon` (
  `id_kon` int(11) DEFAULT NULL,
  `id_mon` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_czech_ci;

--
-- Dumping data for table `kon_mon`
--

INSERT INTO `kon_mon` (`id_kon`, `id_mon`) VALUES
(1, 1),
(1, 3),
(2, 7),
(3, 12),
(3, 13),
(5, 22),
(5, 24),
(5, 25),
(8, 1),
(7, 1),
(9, 2),
(5, 3),
(7, 3),
(4, 5),
(3, 6),
(7, 7),
(9, 7),
(4, 7),
(9, 8),
(6, 8),
(6, 9),
(9, 9),
(3, 9),
(5, 10),
(10, 11),
(6, 11),
(8, 12),
(7, 12),
(6, 12),
(5, 14),
(10, 14),
(2, 14),
(8, 14),
(1, 16),
(5, 16),
(5, 17),
(6, 17),
(8, 17),
(2, 19),
(7, 21),
(7, 22),
(3, 23),
(1, 24),
(4, 24),
(2, 1),
(10, 1),
(3, 1),
(4, 2),
(8, 3),
(9, 3),
(6, 4),
(6, 5),
(5, 5),
(2, 6),
(4, 6),
(9, 6),
(6, 7),
(10, 7),
(8, 8),
(10, 8),
(1, 8),
(1, 9),
(7, 10),
(4, 10),
(9, 10),
(1, 10),
(1, 11),
(9, 11),
(3, 11),
(2, 12),
(5, 12),
(4, 12),
(9, 13),
(6, 14),
(4, 14),
(4, 15),
(1, 15),
(2, 15),
(10, 16),
(9, 16),
(2, 16),
(7, 17),
(9, 17),
(2, 18),
(10, 19),
(8, 19),
(10, 20),
(6, 20),
(1, 20),
(6, 21),
(8, 21),
(9, 22),
(5, 23);

-- --------------------------------------------------------

--
-- Table structure for table `monitory`
--

CREATE TABLE `monitory` (
  `id` int(11) NOT NULL,
  `nazev` varchar(50) DEFAULT NULL,
  `id_vyrobce` int(11) DEFAULT NULL,
  `id_uhlopricka` int(11) DEFAULT NULL,
  `id_typ_panelu` int(11) DEFAULT NULL,
  `id_rozliseni` int(11) DEFAULT NULL,
  `id_frekvence` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_czech_ci;

--
-- Dumping data for table `monitory`
--

INSERT INTO `monitory` (`id`, `nazev`, `id_vyrobce`, `id_uhlopricka`, `id_typ_panelu`, `id_rozliseni`, `id_frekvence`) VALUES
(1, 'Odyssey G5', 1, 4, 2, 6, 7),
(2, 'Odyssey G9', 1, 4, 4, 2, 3),
(3, 'C34H890', 1, 2, 1, 9, 2),
(4, 'ViewFinity S80PB', 1, 4, 1, 1, 8),
(5, 'Odyssey G8 Neo', 1, 7, 2, 9, 8),
(6, 'Odyssey G40B', 1, 7, 3, 5, 7),
(7, 'UltraSharp U2719D', 5, 9, 5, 10, 2),
(8, 'S2419HGF', 5, 7, 5, 6, 7),
(9, 'AW3418DW', 5, 3, 1, 6, 2),
(10, 'U3219Q', 5, 3, 4, 7, 3),
(11, 'P2419H', 5, 6, 1, 10, 5),
(12, '27UK850-W', 2, 5, 2, 9, 6),
(13, '34UC79G-B', 2, 8, 2, 9, 8),
(14, '32UD99-W', 2, 2, 1, 12, 3),
(15, '38GL950G-B', 2, 3, 1, 4, 2),
(16, '27GL850-B', 2, 9, 3, 5, 1),
(17, 'TH-55LFV70', 4, 9, 2, 3, 4),
(18, 'TH-49SF2', 4, 1, 2, 7, 3),
(19, 'TH-55EQ1W', 4, 2, 8, 2, 7),
(20, 'TH-75BQE1W', 4, 4, 3, 5, 8),
(21, 'LMD-A240', 3, 5, 6, 4, 2),
(22, 'PVM-A170', 3, 8, 3, 1, 4),
(23, 'FW-55BZ35F', 3, 2, 1, 11, 3),
(24, 'BVM-HX310', 3, 5, 8, 11, 8),
(25, 'LMD-B170', 3, 8, 1, 1, 8);

-- --------------------------------------------------------

--
-- Stand-in structure for view `monitor_view`
-- (See below for the actual view)
--
CREATE TABLE `monitor_view` (
`id` int(11)
,`monitor` varchar(50)
,`vyrobce` varchar(50)
,`popis_vyrobce` varchar(500)
,`uhlopricka` varchar(23)
,`typ_panelu` varchar(20)
,`rozliseni_nazev` varchar(50)
,`rozliseni_sirka` varchar(23)
,`rozliseni_vyska` varchar(23)
,`frekvence` varchar(23)
,`konektory_monitoru` mediumtext
,`funkce_monitoru` mediumtext
,`prumerne_hodnoceni` decimal(14,4)
,`pocet_recenzi` bigint(21)
);

-- --------------------------------------------------------

--
-- Table structure for table `recenze`
--

CREATE TABLE `recenze` (
  `id` int(11) NOT NULL,
  `hodnoceni` int(11) DEFAULT NULL,
  `text` varchar(255) DEFAULT NULL,
  `id_uzivatel` int(11) DEFAULT NULL,
  `id_monitor` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `recenze`
--

INSERT INTO `recenze` (`id`, `hodnoceni`, `text`, `id_uzivatel`, `id_monitor`) VALUES
(1, 4, 'Dobrý monitor s vynikajícím výkonem.', 3, 12),
(2, 3, 'Slabý obraz a horší kvalita zpracování.', 8, 6),
(3, 5, 'Velmi spokojen s výkonem a designem monitoru.', 5, 20),
(4, 2, 'Průměrný monitor s nedostatečným osvětlením.', 1, 10),
(5, 4, 'Skvělá cena za výborný obrazový výkon.', 6, 15),
(6, 3, 'Nespolehlivý monitor s častými technickými problémy.', 4, 9),
(7, 5, 'Vynikající barevné podání a široké pozorovací úhly.', 2, 18),
(8, 4, 'Kvalitní obraz a rychlá odezva, doporučuji pro hraní her.', 9, 24),
(9, 3, 'Průměrný monitor, nic extra.', 7, 13),
(10, 5, 'Výborná kvalita obrazu a elegantní design.', 10, 22),
(11, 4, 'Skvělý monitor pro grafickou práci s vysokým rozlišením.', 6, 21),
(12, 3, 'Problémy s obrazovkou po krátké době používání.', 2, 7),
(13, 5, 'Vynikající monitor s plynulým obrazem a vysokým kontrastem.', 9, 16),
(14, 4, 'Dobrý výkon a kvalita za přijatelnou cenu.', 5, 23),
(15, 3, 'Průměrný monitor s obyčejnými funkcemi.', 8, 14),
(16, 5, 'Vynikající monitor s ostrým obrazem a bohatými barvami.', 3, 19),
(17, 4, 'Kvalitní monitor s výbornou odezvou.', 7, 11),
(18, 2, 'Nedoporučuji tento monitor, problémy s obrazovkou.', 9, 14),
(19, 4, 'Vynikající monitor s jasnými barvami a výborným kontrastem.', 2, 23),
(20, 3, 'Průměrná kvalita za dostupnou cenu.', 7, 17),
(21, 4, 'Tento monitor předčil mé očekávání.', 7, 19),
(22, 3, 'Solidní monitor za přijatelnou cenu.', 5, 12),
(23, 5, 'Nejlepší monitor, který jsem kdy měl!', 10, 25),
(24, 1, 'Zklamání, monitor se často přehřívá.', 3, 8),
(25, 4, 'Velmi pěkný design a skvělá kvalita obrazu.', 9, 21),
(26, 5, 'Skvělý monitor pro práci i zábavu.', 2, 10),
(27, 1, 'Hrůzná kvalita obrazu, nedoporučuji.', 1, 5),
(28, 4, 'Přesně to, co jsem potřeboval, žádné problémy.', 8, 18),
(29, 3, 'Průměrný monitor za přiměřenou cenu.', 6, 15),
(30, 5, 'Jasný obraz, žádné rozmazání, velmi spokojený.', 4, 9),
(31, 2, 'Špatná odezva, nedoporučuji pro hraní her.', 7, 22),
(32, 4, 'Dostatečně velký monitor s bohatými barvami.', 3, 7),
(33, 5, 'Nejlepší monitor v této cenové kategorii.', 10, 24),
(34, 3, 'Nemá dostatečné možnosti nastavení.', 5, 13),
(35, 4, 'Pěkný design, jednoduchá instalace.', 9, 20),
(36, 1, 'Monitor přišel poškozený, velmi nespokojený.', 6, 16),
(37, 5, 'Překrásné barevné podání, doporučuji pro grafickou práci.', 2, 11),
(38, 3, 'Občasné problémy s rozlišením.', 4, 23),
(39, 4, 'Skvělý poměr cena/výkon, spokojenost.', 8, 17),
(40, 5, 'Vynikající monitor s úžasnými barevnými podáními.', 6, 14),
(41, 4, 'Tento monitor předčil mé očekávání.', 6, 24),
(42, 3, 'Solidní monitor za přijatelnou cenu.', 10, 7),
(43, 5, 'Nejlepší monitor, který jsem kdy měl!', 3, 18),
(44, 2, 'Zklamání, monitor se často přehřívá.', 7, 16),
(45, 4, 'Velmi pěkný design a skvělá kvalita obrazu.', 2, 25),
(46, 5, 'Skvělý monitor pro práci i zábavu.', 5, 12),
(47, 1, 'Hrůzná kvalita obrazu, nedoporučuji.', 8, 11),
(48, 4, 'Přesně to, co jsem potřeboval, žádné problémy.', 9, 21),
(49, 3, 'Průměrný monitor za přiměřenou cenu.', 4, 14),
(50, 5, 'Jasný obraz, žádné rozmazání, velmi spokojený.', 1, 15),
(51, 2, 'Špatná odezva, nedoporučuji pro hraní her.', 6, 10),
(52, 4, 'Dostatečně velký monitor s bohatými barvami.', 3, 19),
(53, 5, 'Nejlepší monitor v této cenové kategorii.', 7, 13),
(54, 3, 'Nemá dostatečné možnosti nastavení.', 10, 23),
(55, 4, 'Pěkný design, jednoduchá instalace.', 5, 22),
(56, 1, 'Monitor přišel poškozený, velmi nespokojený.', 8, 20),
(57, 5, 'Překrásné barevné podání, doporučuji pro grafickou práci.', 2, 17),
(58, 3, 'Občasné problémy s rozlišením.', 9, 8),
(59, 4, 'Skvělý poměr cena/výkon, spokojenost.', 4, 9),
(60, 5, 'Vynikající monitor s úžasnými barevnými podáními.', 6, 6),
(61, 4, 'Tento monitor předčil mé očekávání.', 2, 18),
(62, 3, 'Solidní monitor za přijatelnou cenu.', 2, 18),
(63, 5, 'Nejlepší monitor, který jsem kdy měl!', 1, 8),
(64, 2, 'Zklamání, monitor se často přehřívá.', 4, 15),
(65, 4, 'Velmi pěkný design a skvělá kvalita obrazu.', 10, 6),
(66, 5, 'Skvělý monitor pro práci i zábavu.', 1, 17),
(67, 1, 'Hrůzná kvalita obrazu, nedoporučuji.', 1, 13),
(68, 4, 'Přesně to, co jsem potřeboval, žádné problémy.', 3, 14),
(69, 3, 'Průměrný monitor za přiměřenou cenu.', 1, 18),
(70, 5, 'Jasný obraz, žádné rozmazání, velmi spokojený.', 4, 21),
(71, 2, 'Špatná odezva, nedoporučuji pro hraní her.', 10, 7),
(72, 4, 'Dostatečně velký monitor s bohatými barvami.', 5, 7),
(73, 5, 'Nejlepší monitor v této cenové kategorii.', 2, 3),
(74, 3, 'Nemá dostatečné možnosti nastavení.', 9, 2),
(75, 4, 'Pěkný design, jednoduchá instalace.', 7, 5),
(76, 1, 'Monitor přišel poškozený, velmi nespokojený.', 10, 8),
(77, 5, 'Překrásné barevné podání, doporučuji pro grafickou práci.', 6, 18),
(78, 3, 'Občasné problémy s rozlišením.', 10, 22),
(79, 4, 'Skvělý poměr cena/výkon, spokojenost.', 3, 21),
(80, 5, 'Vynikající monitor s úžasnými barevnými podáními.', 4, 1),
(81, 4, 'Tento monitor předčil mé očekávání.', 3, 6),
(82, 3, 'Solidní monitor za přijatelnou cenu.', 3, 21),
(83, 5, 'Nejlepší monitor, který jsem kdy měl!', 2, 12),
(84, 2, 'Zklamání, monitor se často přehřívá.', 9, 17),
(85, 4, 'Velmi pěkný design a skvělá kvalita obrazu.', 10, 15),
(86, 5, 'Skvělý monitor pro práci i zábavu.', 1, 18),
(87, 1, 'Hrůzná kvalita obrazu, nedoporučuji.', 4, 14),
(88, 4, 'Přesně to, co jsem potřeboval, žádné problémy.', 8, 1),
(89, 3, 'Průměrný monitor za přiměřenou cenu.', 10, 15),
(90, 5, 'Jasný obraz, žádné rozmazání, velmi spokojený.', 1, 18),
(91, 2, 'Špatná odezva, nedoporučuji pro hraní her.', 3, 25),
(92, 4, 'Dostatečně velký monitor s bohatými barvami.', 3, 8),
(93, 5, 'Nejlepší monitor v této cenové kategorii.', 8, 25),
(94, 3, 'Nemá dostatečné možnosti nastavení.', 7, 6),
(95, 4, 'Pěkný design, jednoduchá instalace.', 3, 12),
(96, 1, 'Monitor přišel poškozený, velmi nespokojený.', 6, 11),
(97, 5, 'Překrásné barevné podání, doporučuji pro grafickou práci.', 5, 22),
(98, 3, 'Občasné problémy s rozlišením.', 1, 14),
(99, 4, 'Skvělý poměr cena/výkon, spokojenost.', 8, 21),
(100, 5, 'Vynikající monitor s úžasnými barevnými podáními.', 1, 24),
(101, 4, 'Tento monitor předčil mé očekávání.', 5, 7),
(102, 3, 'Solidní monitor za přijatelnou cenu.', 1, 17),
(103, 5, 'Nejlepší monitor, který jsem kdy měl!', 1, 6),
(104, 2, 'Zklamání, monitor se často přehřívá.', 10, 8),
(105, 4, 'Velmi pěkný design a skvělá kvalita obrazu.', 5, 14),
(106, 5, 'Skvělý monitor pro práci i zábavu.', 4, 22),
(107, 1, 'Hrůzná kvalita obrazu, nedoporučuji.', 5, 14),
(108, 4, 'Přesně to, co jsem potřeboval, žádné problémy.', 5, 13),
(109, 3, 'Průměrný monitor za přiměřenou cenu.', 2, 9),
(110, 5, 'Jasný obraz, žádné rozmazání, velmi spokojený.', 2, 23),
(111, 2, 'Špatná odezva, nedoporučuji pro hraní her.', 10, 1),
(112, 4, 'Dostatečně velký monitor s bohatými barvami.', 4, 15),
(113, 5, 'Nejlepší monitor v této cenové kategorii.', 9, 9),
(114, 3, 'Nemá dostatečné možnosti nastavení.', 4, 17),
(115, 4, 'Pěkný design, jednoduchá instalace.', 3, 11),
(116, 1, 'Monitor přišel poškozený, velmi nespokojený.', 3, 23),
(117, 5, 'Překrásné barevné podání, doporučuji pro grafickou práci.', 9, 15),
(118, 3, 'Občasné problémy s rozlišením.', 3, 19),
(119, 4, 'Skvělý poměr cena/výkon, spokojenost.', 9, 23),
(120, 5, 'Vynikající monitor s úžasnými barevnými podáními.', 1, 12),
(121, 4, 'Tento monitor předčil mé očekávání.', 3, 21),
(122, 3, 'Solidní monitor za přijatelnou cenu.', 4, 5),
(123, 5, 'Nejlepší monitor, který jsem kdy měl!', 1, 12),
(124, 2, 'Zklamání, monitor se často přehřívá.', 3, 1),
(125, 4, 'Velmi pěkný design a skvělá kvalita obrazu.', 3, 2),
(126, 5, 'Skvělý monitor pro práci i zábavu.', 6, 20),
(127, 1, 'Hrůzná kvalita obrazu, nedoporučuji.', 2, 10),
(128, 4, 'Přesně to, co jsem potřeboval, žádné problémy.', 5, 1),
(129, 3, 'Průměrný monitor za přiměřenou cenu.', 8, 22),
(130, 5, 'Jasný obraz, žádné rozmazání, velmi spokojený.', 10, 3),
(131, 2, 'Špatná odezva, nedoporučuji pro hraní her.', 8, 15),
(132, 4, 'Dostatečně velký monitor s bohatými barvami.', 7, 8),
(133, 5, 'Nejlepší monitor v této cenové kategorii.', 7, 12),
(134, 3, 'Nemá dostatečné možnosti nastavení.', 2, 16),
(135, 4, 'Pěkný design, jednoduchá instalace.', 6, 23),
(136, 1, 'Monitor přišel poškozený, velmi nespokojený.', 10, 21),
(137, 5, 'Překrásné barevné podání, doporučuji pro grafickou práci.', 4, 6),
(138, 3, 'Občasné problémy s rozlišením.', 2, 5),
(139, 4, 'Skvělý poměr cena/výkon, spokojenost.', 4, 10),
(140, 5, 'Vynikající monitor s úžasnými barevnými podáními.', 8, 17),
(141, 4, 'Tento monitor předčil mé očekávání.', 1, 3),
(142, 3, 'Solidní monitor za přijatelnou cenu.', 6, 8),
(143, 5, 'Nejlepší monitor, který jsem kdy měl!', 10, 19),
(144, 2, 'Zklamání, monitor se často přehřívá.', 10, 13),
(145, 4, 'Velmi pěkný design a skvělá kvalita obrazu.', 7, 24),
(146, 5, 'Skvělý monitor pro práci i zábavu.', 6, 25),
(147, 1, 'Hrůzná kvalita obrazu, nedoporučuji.', 4, 16),
(148, 4, 'Přesně to, co jsem potřeboval, žádné problémy.', 2, 1),
(149, 3, 'Průměrný monitor za přiměřenou cenu.', 6, 18),
(150, 5, 'Jasný obraz, žádné rozmazání, velmi spokojený.', 9, 3),
(151, 2, 'Špatná odezva, nedoporučuji pro hraní her.', 10, 8),
(152, 4, 'Dostatečně velký monitor s bohatými barvami.', 8, 23),
(153, 5, 'Nejlepší monitor v této cenové kategorii.', 2, 5),
(154, 3, 'Nemá dostatečné možnosti nastavení.', 5, 14),
(155, 4, 'Pěkný design, jednoduchá instalace.', 6, 22),
(156, 1, 'Monitor přišel poškozený, velmi nespokojený.', 9, 15),
(157, 5, 'Překrásné barevné podání, doporučuji pro grafickou práci.', 4, 25),
(158, 3, 'Občasné problémy s rozlišením.', 10, 16),
(159, 4, 'Skvělý poměr cena/výkon, spokojenost.', 5, 7),
(160, 5, 'Vynikající monitor s úžasnými barevnými podáními.', 10, 2),
(161, 4, 'Tento monitor předčil mé očekávání.', 4, 16),
(162, 3, 'Solidní monitor za přijatelnou cenu.', 1, 6),
(163, 5, 'Nejlepší monitor, který jsem kdy měl!', 10, 8),
(164, 2, 'Zklamání, monitor se často přehřívá.', 7, 3),
(165, 4, 'Velmi pěkný design a skvělá kvalita obrazu.', 8, 7),
(166, 5, 'Skvělý monitor pro práci i zábavu.', 1, 18),
(167, 1, 'Hrůzná kvalita obrazu, nedoporučuji.', 3, 25),
(168, 4, 'Přesně to, co jsem potřeboval, žádné problémy.', 3, 12),
(169, 3, 'Průměrný monitor za přiměřenou cenu.', 5, 22),
(170, 5, 'Jasný obraz, žádné rozmazání, velmi spokojený.', 10, 4),
(171, 2, 'Špatná odezva, nedoporučuji pro hraní her.', 8, 16),
(172, 4, 'Dostatečně velký monitor s bohatými barvami.', 8, 20),
(173, 5, 'Nejlepší monitor v této cenové kategorii.', 8, 13),
(174, 3, 'Nemá dostatečné možnosti nastavení.', 3, 16),
(175, 4, 'Pěkný design, jednoduchá instalace.', 5, 11),
(176, 1, 'Monitor přišel poškozený, velmi nespokojený.', 8, 15),
(177, 5, 'Překrásné barevné podání, doporučuji pro grafickou práci.', 6, 1),
(178, 3, 'Občasné problémy s rozlišením.', 5, 6),
(179, 4, 'Skvělý poměr cena/výkon, spokojenost.', 8, 3),
(180, 5, 'Vynikající monitor s úžasnými barevnými podáními.', 3, 21),
(181, 4, 'Tento monitor předčil mé očekávání.', 4, 14),
(182, 3, 'Solidní monitor za přijatelnou cenu.', 6, 7),
(183, 5, 'Nejlepší monitor, který jsem kdy měl!', 7, 6),
(184, 2, 'Zklamání, monitor se často přehřívá.', 2, 9),
(185, 4, 'Velmi pěkný design a skvělá kvalita obrazu.', 1, 13),
(186, 5, 'Skvělý monitor pro práci i zábavu.', 2, 11),
(187, 1, 'Hrůzná kvalita obrazu, nedoporučuji.', 6, 11),
(188, 4, 'Přesně to, co jsem potřeboval, žádné problémy.', 6, 15),
(189, 3, 'Průměrný monitor za přiměřenou cenu.', 2, 1),
(190, 5, 'Jasný obraz, žádné rozmazání, velmi spokojený.', 6, 23),
(191, 2, 'Špatná odezva, nedoporučuji pro hraní her.', 8, 22),
(192, 4, 'Dostatečně velký monitor s bohatými barvami.', 3, 12),
(193, 5, 'Nejlepší monitor v této cenové kategorii.', 8, 8),
(194, 3, 'Nemá dostatečné možnosti nastavení.', 3, 5),
(195, 4, 'Pěkný design, jednoduchá instalace.', 4, 5),
(196, 1, 'Monitor přišel poškozený, velmi nespokojený.', 8, 10),
(197, 5, 'Překrásné barevné podání, doporučuji pro grafickou práci.', 6, 21),
(198, 3, 'Občasné problémy s rozlišením.', 4, 5),
(199, 4, 'Skvělý poměr cena/výkon, spokojenost.', 10, 6),
(200, 5, 'Vynikající monitor s úžasnými barevnými podáními.', 3, 12);

--
-- Triggers `recenze`
--
DELIMITER $$
CREATE TRIGGER `update_recenze_trigger` AFTER UPDATE ON `recenze` FOR EACH ROW BEGIN
    INSERT INTO update_log_recenze (table_name, record_id, update_timestamp, updated_by)
    VALUES ('recenze', NEW.id, NOW(), CURRENT_USER());
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Stand-in structure for view `recenze_view`
-- (See below for the actual view)
--
CREATE TABLE `recenze_view` (
`uzivatel_jmeno` varchar(50)
,`monitor` varchar(50)
,`vyrobce` varchar(50)
,`textove_hodnoceni` varchar(255)
,`hodnoceni` int(11)
);

-- --------------------------------------------------------

--
-- Table structure for table `rozliseni`
--

CREATE TABLE `rozliseni` (
  `id` int(11) NOT NULL,
  `nazev` varchar(50) NOT NULL,
  `vyska` int(11) DEFAULT NULL,
  `sirka` int(11) DEFAULT NULL,
  `id_jednotka` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_czech_ci;

--
-- Dumping data for table `rozliseni`
--

INSERT INTO `rozliseni` (`id`, `nazev`, `vyska`, `sirka`, `id_jednotka`) VALUES
(1, 'HD', 720, 1280, 2),
(2, 'WXGA', 768, 1366, 2),
(3, 'HD+', 900, 1600, 2),
(4, 'Full HD', 1080, 1920, 2),
(5, 'WUXGA', 1200, 1920, 2),
(6, 'Quad HD', 1440, 2560, 2),
(7, 'QHD+', 1600, 2560, 2),
(8, 'Ultra HD 4K', 2160, 3840, 2),
(9, 'WQUXGA', 2400, 3840, 2),
(10, '5K', 2880, 5120, 2),
(11, '5K+', 3200, 5120, 2),
(12, 'Ultra HD 8K', 4320, 7680, 2);

-- --------------------------------------------------------

--
-- Table structure for table `typy_panelu`
--

CREATE TABLE `typy_panelu` (
  `id` int(11) NOT NULL,
  `nazev` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_czech_ci;

--
-- Dumping data for table `typy_panelu`
--

INSERT INTO `typy_panelu` (`id`, `nazev`) VALUES
(1, 'TN'),
(2, 'IPS'),
(3, 'VA'),
(4, 'OLED'),
(5, 'LED'),
(6, 'AMOLED'),
(7, 'QLED'),
(8, 'LED');

-- --------------------------------------------------------

--
-- Table structure for table `uhlopricky`
--

CREATE TABLE `uhlopricky` (
  `id` int(11) NOT NULL,
  `velikost` int(11) DEFAULT NULL,
  `id_jednotka` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_czech_ci;

--
-- Dumping data for table `uhlopricky`
--

INSERT INTO `uhlopricky` (`id`, `velikost`, `id_jednotka`) VALUES
(1, 19, 1),
(2, 21, 1),
(3, 24, 1),
(4, 27, 1),
(5, 32, 1),
(6, 34, 1),
(7, 38, 1),
(8, 49, 1),
(9, 55, 1);

-- --------------------------------------------------------

--
-- Table structure for table `update_log_recenze`
--

CREATE TABLE `update_log_recenze` (
  `log_id` int(11) NOT NULL,
  `table_name` varchar(255) NOT NULL,
  `record_id` int(11) NOT NULL,
  `update_timestamp` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `updated_by` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `update_log_recenze`
--

INSERT INTO `update_log_recenze` (`log_id`, `table_name`, `record_id`, `update_timestamp`, `updated_by`) VALUES
(1, 'recenze', 24, '2024-01-15 15:21:05', 'root@localhost');

-- --------------------------------------------------------

--
-- Table structure for table `users_multiple_reviews`
--

CREATE TABLE `users_multiple_reviews` (
  `user_id` int(11) DEFAULT NULL,
  `review_count` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users_multiple_reviews`
--

INSERT INTO `users_multiple_reviews` (`user_id`, `review_count`) VALUES
(10, 23),
(1, 19),
(2, 21),
(3, 26),
(4, 21),
(5, 18),
(6, 22),
(7, 14),
(8, 22),
(9, 14);

-- --------------------------------------------------------

--
-- Table structure for table `uzivatele`
--

CREATE TABLE `uzivatele` (
  `id` int(11) NOT NULL,
  `email` varchar(50) DEFAULT NULL,
  `jmeno` varchar(50) DEFAULT NULL,
  `heslo` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `uzivatele`
--

INSERT INTO `uzivatele` (`id`, `email`, `jmeno`, `heslo`) VALUES
(1, 'user1@example.com', 'Jan Novák', 'heslo1'),
(2, 'user2@example.com', 'Jana Nováková', 'heslo2'),
(3, 'user3@example.com', 'Petr Svoboda', 'heslo3'),
(4, 'user4@example.com', 'Kateřina Procházková', 'heslo4'),
(5, 'user5@example.com', 'Martin Kovář', 'heslo5'),
(6, 'user6@example.com', 'Eva Novotná', 'heslo6'),
(7, 'user7@example.com', 'Tomáš Procházka', 'heslo7'),
(8, 'user8@example.com', 'Veronika Marešová', 'heslo8'),
(9, 'user9@example.com', 'Jakub Dvořák', 'heslo9'),
(10, 'user10@example.com', 'Tereza Nová', 'heslo10');

-- --------------------------------------------------------

--
-- Table structure for table `vyrobci`
--

CREATE TABLE `vyrobci` (
  `id` int(11) NOT NULL,
  `nazev` varchar(50) DEFAULT NULL,
  `popis` varchar(500) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_czech_ci;

--
-- Dumping data for table `vyrobci`
--

INSERT INTO `vyrobci` (`id`, `nazev`, `popis`) VALUES
(1, 'Samsung', 'Samsung je jedním z největších producentů displejů na světě. Firma nabízí širokou škálu displejů pro různá zařízení, včetně televizí, monitorů, laptopů a smartphonů. Je známo pro svou kvalitu obrazu a inovativní technologie, jako jsou OLED a QLED displeje.'),
(2, 'LG', 'LG je dalším významným výrobcem displejů, který nabízí širokou škálu produktů. Společnost je známa svými televizory, monitory, mobilními telefony a dalšími elektronickými zařízeními. LG je známé pro své OLED displeje, které poskytují vynikající kvalitu obrazu a kontrast.\n'),
(3, 'Sony', 'Sony je renomovaný výrobce displejů s dlouholetou historií. Společnost nabízí širokou škálu televizorů, monitorů, notebooků a smartphonů. Displeje od Sony jsou obecně ceněny pro svou vysokou kvalitu zobrazení a živé barvy.\n'),
(4, 'Panasonic', 'Panasonic je další společnost, která se zabývá výrobou kvalitních displejů. Nabízí různé typy displejů pro televize, monitory, projekční zařízení a další produkty. Displeje od Panasonicu jsou obecně považovány za spolehlivé a nabízejí realistické zobrazení.\n'),
(5, 'Dell', 'Dell je známý výrobce počítačů a monitorů. Společnost nabízí širokou škálu displejů různých velikostí pro spotřebitele i profesionály. Displeje od Dellu jsou často oceněny pro svou vysokou kvalitu obrazu a ergonomický design.\n');

-- --------------------------------------------------------

--
-- Structure for view `monitor_view`
--
DROP TABLE IF EXISTS `monitor_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `monitor_view`  AS SELECT `m`.`id` AS `id`, `m`.`nazev` AS `monitor`, `v`.`nazev` AS `vyrobce`, `v`.`popis` AS `popis_vyrobce`, concat(`u`.`velikost`,`j1`.`zkratka`) AS `uhlopricka`, `tp`.`nazev` AS `typ_panelu`, `r`.`nazev` AS `rozliseni_nazev`, concat(`r`.`sirka`,`j2`.`zkratka`) AS `rozliseni_sirka`, concat(`r`.`vyska`,`j2`.`zkratka`) AS `rozliseni_vyska`, concat(`f`.`hodnota`,`j3`.`zkratka`) AS `frekvence`, group_concat(distinct `k`.`typ` separator ',') AS `konektory_monitoru`, group_concat(distinct `fu`.`nazev` separator ',') AS `funkce_monitoru`, avg(`rn`.`hodnoceni`) AS `prumerne_hodnoceni`, count(distinct `rn`.`id`) AS `pocet_recenzi` FROM (((((((((((((`monitory` `m` join `vyrobci` `v` on(`m`.`id_vyrobce` = `v`.`id`)) join `uhlopricky` `u` on(`m`.`id_uhlopricka` = `u`.`id`)) join `typy_panelu` `tp` on(`m`.`id_typ_panelu` = `tp`.`id`)) join `rozliseni` `r` on(`m`.`id_rozliseni` = `r`.`id`)) join `frekvence` `f` on(`m`.`id_frekvence` = `f`.`id`)) join `kon_mon` `km` on(`m`.`id` = `km`.`id_mon`)) join `konektory` `k` on(`km`.`id_kon` = `k`.`id`)) join `fun_mon` `fm` on(`m`.`id` = `fm`.`id_mon`)) join `funkce` `fu` on(`fm`.`id_fun` = `fu`.`id`)) join `jednotky` `j1` on(`u`.`id_jednotka` = `j1`.`id`)) join `jednotky` `j2` on(`r`.`id_jednotka` = `j2`.`id`)) join `jednotky` `j3` on(`f`.`id_jednotka` = `j3`.`id`)) left join `recenze` `rn` on(`m`.`id` = `rn`.`id_monitor`)) GROUP BY `m`.`id` HAVING count(`rn`.`id`) > 0 ORDER BY `m`.`id` ASC ;

-- --------------------------------------------------------

--
-- Structure for view `recenze_view`
--
DROP TABLE IF EXISTS `recenze_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `recenze_view`  AS SELECT `u`.`jmeno` AS `uzivatel_jmeno`, `m`.`nazev` AS `monitor`, `v`.`nazev` AS `vyrobce`, `r`.`text` AS `textove_hodnoceni`, `r`.`hodnoceni` AS `hodnoceni` FROM (((`recenze` `r` join `uzivatele` `u` on(`r`.`id_uzivatel` = `u`.`id`)) join `monitory` `m` on(`r`.`id_monitor` = `m`.`id`)) join `vyrobci` `v` on(`m`.`id_vyrobce` = `v`.`id`)) GROUP BY `r`.`id` ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `frekvence`
--
ALTER TABLE `frekvence`
  ADD PRIMARY KEY (`id`),
  ADD KEY `FK_Frekvence_Jednotky` (`id_jednotka`);

--
-- Indexes for table `funkce`
--
ALTER TABLE `funkce`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `fun_mon`
--
ALTER TABLE `fun_mon`
  ADD KEY `id_kon` (`id_fun`),
  ADD KEY `id_mon` (`id_mon`);

--
-- Indexes for table `jednotky`
--
ALTER TABLE `jednotky`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `kategorie`
--
ALTER TABLE `kategorie`
  ADD PRIMARY KEY (`id`),
  ADD KEY `parent_id` (`id_nadkategorie`);

--
-- Indexes for table `kat_mon`
--
ALTER TABLE `kat_mon`
  ADD KEY `id_mon` (`id_mon`),
  ADD KEY `id_kat` (`id_kat`);

--
-- Indexes for table `konektory`
--
ALTER TABLE `konektory`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `kon_mon`
--
ALTER TABLE `kon_mon`
  ADD KEY `id_kon` (`id_kon`),
  ADD KEY `id_mon` (`id_mon`);

--
-- Indexes for table `monitory`
--
ALTER TABLE `monitory`
  ADD PRIMARY KEY (`id`),
  ADD KEY `uhlopricka_id` (`id_uhlopricka`),
  ADD KEY `vyrobce_id` (`id_vyrobce`),
  ADD KEY `rozliseni_id` (`id_rozliseni`),
  ADD KEY `frekvence_id` (`id_frekvence`),
  ADD KEY `typ_panelu_id` (`id_typ_panelu`);

--
-- Indexes for table `recenze`
--
ALTER TABLE `recenze`
  ADD PRIMARY KEY (`id`),
  ADD KEY `uzivatel_id` (`id_uzivatel`),
  ADD KEY `FK_Rozliseni_Monitory` (`id_monitor`);
ALTER TABLE `recenze` ADD FULLTEXT KEY `idx_recenze_text` (`text`);

--
-- Indexes for table `rozliseni`
--
ALTER TABLE `rozliseni`
  ADD PRIMARY KEY (`id`),
  ADD KEY `FK_Rozliseni_Jednotky` (`id_jednotka`);

--
-- Indexes for table `typy_panelu`
--
ALTER TABLE `typy_panelu`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `uhlopricky`
--
ALTER TABLE `uhlopricky`
  ADD PRIMARY KEY (`id`),
  ADD KEY `FK_Uhlopricka_Jednotky` (`id_jednotka`);

--
-- Indexes for table `update_log_recenze`
--
ALTER TABLE `update_log_recenze`
  ADD PRIMARY KEY (`log_id`);

--
-- Indexes for table `uzivatele`
--
ALTER TABLE `uzivatele`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `idx_uzivatele_email` (`email`);

--
-- Indexes for table `vyrobci`
--
ALTER TABLE `vyrobci`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `frekvence`
--
ALTER TABLE `frekvence`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=35;

--
-- AUTO_INCREMENT for table `funkce`
--
ALTER TABLE `funkce`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `konektory`
--
ALTER TABLE `konektory`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=171;

--
-- AUTO_INCREMENT for table `monitory`
--
ALTER TABLE `monitory`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=103;

--
-- AUTO_INCREMENT for table `recenze`
--
ALTER TABLE `recenze`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=201;

--
-- AUTO_INCREMENT for table `rozliseni`
--
ALTER TABLE `rozliseni`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=188;

--
-- AUTO_INCREMENT for table `typy_panelu`
--
ALTER TABLE `typy_panelu`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `uhlopricky`
--
ALTER TABLE `uhlopricky`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `update_log_recenze`
--
ALTER TABLE `update_log_recenze`
  MODIFY `log_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `vyrobci`
--
ALTER TABLE `vyrobci`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=128;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `frekvence`
--
ALTER TABLE `frekvence`
  ADD CONSTRAINT `FK_Frekvence_Jednotky` FOREIGN KEY (`id_jednotka`) REFERENCES `jednotky` (`id`);

--
-- Constraints for table `fun_mon`
--
ALTER TABLE `fun_mon`
  ADD CONSTRAINT `fun_mon_ibfk_1` FOREIGN KEY (`id_fun`) REFERENCES `funkce` (`id`),
  ADD CONSTRAINT `fun_mon_ibfk_2` FOREIGN KEY (`id_mon`) REFERENCES `monitory` (`id`);

--
-- Constraints for table `kategorie`
--
ALTER TABLE `kategorie`
  ADD CONSTRAINT `kategorie_ibfk_1` FOREIGN KEY (`id_nadkategorie`) REFERENCES `kategorie` (`id`);

--
-- Constraints for table `kat_mon`
--
ALTER TABLE `kat_mon`
  ADD CONSTRAINT `kat_mon_ibfk_1` FOREIGN KEY (`id_mon`) REFERENCES `monitory` (`id`),
  ADD CONSTRAINT `kat_mon_ibfk_2` FOREIGN KEY (`id_kat`) REFERENCES `kategorie` (`id`);

--
-- Constraints for table `kon_mon`
--
ALTER TABLE `kon_mon`
  ADD CONSTRAINT `kon_mon_ibfk_1` FOREIGN KEY (`id_kon`) REFERENCES `konektory` (`id`),
  ADD CONSTRAINT `kon_mon_ibfk_2` FOREIGN KEY (`id_mon`) REFERENCES `monitory` (`id`);

--
-- Constraints for table `monitory`
--
ALTER TABLE `monitory`
  ADD CONSTRAINT `monitory_ibfk_1` FOREIGN KEY (`id_uhlopricka`) REFERENCES `uhlopricky` (`id`),
  ADD CONSTRAINT `monitory_ibfk_2` FOREIGN KEY (`id_vyrobce`) REFERENCES `vyrobci` (`id`),
  ADD CONSTRAINT `monitory_ibfk_3` FOREIGN KEY (`id_rozliseni`) REFERENCES `rozliseni` (`id`),
  ADD CONSTRAINT `monitory_ibfk_4` FOREIGN KEY (`id_frekvence`) REFERENCES `frekvence` (`id`),
  ADD CONSTRAINT `monitory_ibfk_5` FOREIGN KEY (`id_typ_panelu`) REFERENCES `typy_panelu` (`id`);

--
-- Constraints for table `recenze`
--
ALTER TABLE `recenze`
  ADD CONSTRAINT `FK_Rozliseni_Monitory` FOREIGN KEY (`id_monitor`) REFERENCES `monitory` (`id`),
  ADD CONSTRAINT `recenze_ibfk_1` FOREIGN KEY (`id_uzivatel`) REFERENCES `uzivatele` (`id`);

--
-- Constraints for table `rozliseni`
--
ALTER TABLE `rozliseni`
  ADD CONSTRAINT `FK_Rozliseni_Jednotky` FOREIGN KEY (`id_jednotka`) REFERENCES `jednotky` (`id`);

--
-- Constraints for table `uhlopricky`
--
ALTER TABLE `uhlopricky`
  ADD CONSTRAINT `FK_Uhlopricka_Jednotky` FOREIGN KEY (`id_jednotka`) REFERENCES `jednotky` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
