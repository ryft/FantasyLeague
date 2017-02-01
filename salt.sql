-- MySQL dump 10.15  Distrib 10.0.28-MariaDB, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: localhost
-- ------------------------------------------------------
-- Server version	10.0.28-MariaDB-0ubuntu0.16.04.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `matches`
--

DROP TABLE IF EXISTS `matches`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `matches` (
  `split` int(11) NOT NULL,
  `week` tinyint(4) NOT NULL,
  `games` tinyint(4) NOT NULL DEFAULT '2',
  PRIMARY KEY (`split`,`week`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matches`
--

LOCK TABLES `matches` WRITE;
/*!40000 ALTER TABLE `matches` DISABLE KEYS */;
INSERT INTO `matches` VALUES (1,1,4),(1,2,2),(1,3,2),(1,4,2),(1,5,2),(1,6,2),(1,7,4),(1,8,2),(1,9,2),(1,10,2),(1,11,4),(2,1,2),(2,2,2),(2,3,2),(2,4,2),(2,5,2),(2,6,2),(2,7,2),(2,8,2),(2,9,2),(3,1,2),(3,2,2),(3,3,2),(3,4,2),(3,5,2),(3,6,2),(3,7,2),(3,8,2),(3,9,2);
/*!40000 ALTER TABLE `matches` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matchup`
--

DROP TABLE IF EXISTS `matchup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `matchup` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `split` int(11) NOT NULL,
  `week` tinyint(4) NOT NULL,
  `summoner1` int(11) NOT NULL,
  `summoner2` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=125 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matchup`
--

LOCK TABLES `matchup` WRITE;
/*!40000 ALTER TABLE `matchup` DISABLE KEYS */;
INSERT INTO `matchup` VALUES (1,1,1,1,5),(2,1,1,6,7),(3,1,1,8,4),(4,1,2,1,6),(5,1,2,4,7),(6,1,2,5,8),(7,1,3,1,8),(8,1,3,6,4),(9,1,3,5,7),(10,1,4,1,7),(11,1,4,6,8),(12,1,4,5,4),(13,1,5,1,4),(14,1,5,6,5),(15,1,5,8,7),(16,1,6,1,6),(17,1,6,4,7),(18,1,6,5,8),(19,1,7,1,4),(20,1,7,6,8),(21,1,7,5,7),(22,1,8,1,8),(23,1,8,5,4),(24,1,8,6,7),(25,1,9,1,5),(26,1,9,8,7),(27,1,9,6,4),(28,1,10,1,7),(29,1,10,6,5),(30,1,10,8,4),(31,1,11,1,4),(32,1,11,6,8),(33,1,11,5,7),(34,2,1,1,4),(35,2,1,6,8),(36,2,1,5,7),(37,2,2,1,7),(38,2,2,6,4),(39,2,2,5,8),(40,2,3,1,5),(41,2,3,8,4),(42,2,3,6,7),(43,2,4,1,6),(44,2,4,8,7),(45,2,4,5,4),(46,2,5,1,8),(47,2,5,6,5),(48,2,5,4,7),(49,2,6,1,7),(50,2,6,6,4),(51,2,6,5,8),(52,2,7,1,8),(53,2,7,5,4),(54,2,7,6,7),(55,2,8,1,6),(56,2,8,8,4),(57,2,8,5,7),(58,2,9,1,5),(59,2,9,6,8),(60,2,9,4,7),(61,3,1,1,3),(62,3,1,4,7),(63,3,1,6,8),(64,3,1,5,2),(65,3,2,1,5),(66,3,2,4,3),(67,3,2,8,7),(68,3,2,6,2),(97,3,3,1,6),(98,3,3,2,7),(99,3,3,3,5),(100,3,3,4,8),(101,3,4,1,7),(102,3,4,2,8),(103,3,4,3,6),(104,3,4,4,5),(105,3,5,1,8),(106,3,5,2,4),(107,3,5,3,7),(108,3,5,5,6),(109,3,6,1,2),(110,3,6,3,8),(111,3,6,4,6),(112,3,6,5,7),(113,3,7,1,4),(114,3,7,2,3),(115,3,7,5,8),(116,3,7,6,7),(117,3,8,1,5),(118,3,8,2,6),(119,3,8,3,4),(120,3,8,7,8),(121,3,9,1,6),(122,3,9,2,7),(123,3,9,3,8),(124,3,9,4,5);
/*!40000 ALTER TABLE `matchup` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `result`
--

DROP TABLE IF EXISTS `result`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `result` (
  `split` int(11) NOT NULL,
  `week` tinyint(4) NOT NULL,
  `summoner` int(11) NOT NULL,
  `score` decimal(6,2) DEFAULT NULL,
  PRIMARY KEY (`split`,`week`,`summoner`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `result`
--

LOCK TABLES `result` WRITE;
/*!40000 ALTER TABLE `result` DISABLE KEYS */;
INSERT INTO `result` VALUES (1,1,1,405.87),(1,1,4,429.04),(1,1,5,381.42),(1,1,6,458.59),(1,1,7,470.63),(1,1,8,496.75),(1,2,1,200.46),(1,2,4,196.86),(1,2,5,204.54),(1,2,6,185.88),(1,2,7,201.43),(1,2,8,218.94),(1,3,1,286.82),(1,3,4,217.00),(1,3,5,211.92),(1,3,6,239.49),(1,3,7,201.09),(1,3,8,243.89),(1,4,1,215.16),(1,4,4,213.05),(1,4,5,124.20),(1,4,6,123.35),(1,4,7,208.72),(1,4,8,236.68),(1,5,1,213.50),(1,5,4,268.48),(1,5,5,207.26),(1,5,6,199.40),(1,5,7,257.22),(1,5,8,248.14),(1,6,1,213.10),(1,6,4,180.13),(1,6,5,257.05),(1,6,6,238.47),(1,6,7,234.26),(1,6,8,211.99),(1,7,1,467.07),(1,7,4,398.67),(1,7,5,500.09),(1,7,6,515.51),(1,7,7,476.13),(1,7,8,450.65),(1,8,1,189.62),(1,8,4,168.80),(1,8,5,164.47),(1,8,6,275.97),(1,8,7,265.74),(1,8,8,158.78),(1,9,1,265.74),(1,9,4,256.90),(1,9,5,160.74),(1,9,6,287.48),(1,9,7,245.04),(1,9,8,259.80),(1,10,1,197.03),(1,10,4,236.61),(1,10,5,289.48),(1,10,6,218.46),(1,10,7,203.77),(1,10,8,140.42),(1,11,1,585.86),(1,11,4,413.91),(1,11,5,548.40),(1,11,6,556.91),(1,11,7,533.79),(1,11,8,262.94),(2,1,1,233.98),(2,1,4,228.96),(2,1,5,152.89),(2,1,6,228.96),(2,1,7,202.72),(2,1,8,245.76),(2,2,1,171.60),(2,2,4,261.96),(2,2,5,265.27),(2,2,6,233.51),(2,2,7,311.08),(2,2,8,203.51),(2,3,1,261.63),(2,3,4,277.16),(2,3,5,285.85),(2,3,6,287.74),(2,3,7,323.29),(2,3,8,211.11),(2,4,1,234.70),(2,4,4,301.64),(2,4,5,239.21),(2,4,6,206.46),(2,4,7,289.30),(2,4,8,265.11),(2,5,1,280.76),(2,5,4,243.26),(2,5,5,220.20),(2,5,6,216.40),(2,5,7,268.99),(2,5,8,271.42),(2,6,1,203.47),(2,6,4,224.27),(2,6,5,233.49),(2,6,6,245.77),(2,6,7,289.72),(2,6,8,250.69),(2,7,1,256.49),(2,7,4,260.03),(2,7,5,218.77),(2,7,6,211.73),(2,7,7,198.59),(2,7,8,194.77),(2,8,1,235.05),(2,8,4,286.68),(2,8,5,211.88),(2,8,6,229.62),(2,8,7,294.84),(2,8,8,260.29),(2,9,1,264.33),(2,9,4,333.33),(2,9,5,265.69),(2,9,6,174.02),(2,9,7,233.02),(2,9,8,297.38),(3,1,1,237.80),(3,1,2,314.81),(3,1,3,232.22),(3,1,4,228.80),(3,1,5,217.88),(3,1,6,294.57),(3,1,7,263.67),(3,1,8,346.75),(3,2,1,273.14),(3,2,2,181.66),(3,2,3,228.33),(3,2,4,175.00),(3,2,5,281.72),(3,2,6,271.22),(3,2,7,367.99),(3,2,8,205.88),(3,3,1,298.12),(3,3,2,246.53),(3,3,3,306.85),(3,3,4,243.33),(3,3,5,275.00),(3,3,6,309.23),(3,3,7,212.97),(3,3,8,321.17),(3,4,1,260.88),(3,4,2,271.37),(3,4,3,256.41),(3,4,4,261.61),(3,4,5,291.99),(3,4,6,328.07),(3,4,7,266.98),(3,4,8,197.63),(3,5,1,253.12),(3,5,2,272.45),(3,5,3,236.51),(3,5,4,274.04),(3,5,5,198.08),(3,5,6,225.71),(3,5,7,248.25),(3,5,8,221.54),(3,6,1,250.15),(3,6,2,233.51),(3,6,3,243.66),(3,6,4,222.91),(3,6,5,291.30),(3,6,6,241.30),(3,6,7,246.56),(3,6,8,274.41),(3,7,1,244.21),(3,7,2,316.38),(3,7,3,309.32),(3,7,4,264.78),(3,7,5,178.82),(3,7,6,300.03),(3,7,7,237.12),(3,7,8,375.62),(3,8,1,231.10),(3,8,2,259.54),(3,8,3,234.19),(3,8,4,251.80),(3,8,5,217.08),(3,8,6,261.34),(3,8,7,236.82),(3,8,8,282.80),(3,9,1,245.54),(3,9,2,245.04),(3,9,3,272.90),(3,9,4,193.83),(3,9,5,207.15),(3,9,6,301.03),(3,9,7,173.21),(3,9,8,293.59);
/*!40000 ALTER TABLE `result` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `split`
--

DROP TABLE IF EXISTS `split`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `split` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `start` date NOT NULL,
  `winner` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `split`
--

LOCK TABLES `split` WRITE;
/*!40000 ALTER TABLE `split` DISABLE KEYS */;
INSERT INTO `split` VALUES (1,'Summer 2014','2014-05-20',1),(2,'Spring 2015','2015-01-22',7),(3,'Summer 2015','2015-05-28',6);
/*!40000 ALTER TABLE `split` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `summoner`
--

DROP TABLE IF EXISTS `summoner`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `summoner` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `summoner`
--

LOCK TABLES `summoner` WRITE;
/*!40000 ALTER TABLE `summoner` DISABLE KEYS */;
INSERT INTO `summoner` VALUES (1,'Chu1000000'),(2,'chu1000001'),(3,'McVities'),(4,'Nook93'),(5,'rorschachcbd'),(6,'supersamtaylor'),(7,'Ryft'),(8,'whitelemur');
/*!40000 ALTER TABLE `summoner` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `team`
--

DROP TABLE IF EXISTS `team`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `team` (
  `summoner` int(11) NOT NULL,
  `split` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  PRIMARY KEY (`summoner`,`split`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `team`
--

LOCK TABLES `team` WRITE;
/*!40000 ALTER TABLE `team` DISABLE KEYS */;
INSERT INTO `team` VALUES (1,1,'SamSucksNoob93sBalls'),(1,2,'Chu the Champion'),(1,3,'Smurfing'),(2,3,'Fantasy is izi'),(3,3,'Giraffe Shorts R Hot'),(4,1,'The Shreked Nerds'),(4,2,'SMASHING!'),(4,3,'HISTRIONICS ANON'),(5,1,'I <3 Chink Food'),(5,2,'4.68Stand.Deviations'),(5,3,'Cosmic Imbalance'),(6,1,'Cage\'s Canines'),(6,2,'Team Name'),(6,3,'AssPurgers'),(7,1,'Hinoi Team'),(7,2,'Islamic State'),(7,3,'Bad Luck Buttlecakes'),(8,1,'The Brown Barbies'),(8,2,'KONY\'s KIDS'),(8,3,'weightconcern.org.uk');
/*!40000 ALTER TABLE `team` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2017-02-01 21:34:04
