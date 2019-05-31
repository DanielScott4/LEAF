<?php

function parseDomain($adPath) {
    $dc = '';
    $dcSrc = explode(',', $adPath);
    foreach($dcSrc as $adElement) {
        if(strpos($adElement, 'DC=') !== false) {
            $dc .= substr($adElement, 3) . '.';
        }
    }
    $dc = trim($dc, '.');

    switch($dc) {
      case 'domain.exmaple.com':
        return 'DOMAIN';
      default:
        return $dc;
    }
}

/************************
    VAMC_directory_maintenance
    Date: June 13, 2007

    + Imports data into an employee contact information database
    + Multiple data sources
    + Buffered inserts for low memory usage
*/
class VAMC_Directory_maintenance_AD {
    private $sortBy = 'Lname';          // Sort by... ?
    private $sortDir = 'ASC';           // Sort ascending/descending?
    private $debug = true;             // Are we debugging?

    private $db;                        // The database object
    private $tableName = 'Employee';    // Table of employee contact info
    private $log = array('Debug Log is ON');          // error log for debugging

    private $users = array();

    // Connect to the database
    function __construct()
    {
    	$currDir = dirname(__FILE__);
        require_once $currDir . '/../config.php';
        $config = new Orgchart\Config();
        try {
            $this->db = new PDO("mysql:host={$config->dbHost};dbname={$config->dbName}",
                            $config->dbUser, $config->dbPass, array(PDO::ATTR_PERSISTENT => true));
            unset($config);
        } catch (PDOException $e) {
            echo 'Database Error: ' . $e->getMessage();
            exit();
        }
    }

    function __destruct()
    {
        if($this->debug)
            echo print_r($this->log);     // debugging
    }

    // Log errors from the database
    private function logError($error)
    {
        $this->log[] = $error;
    }

    public function setSort($sortBy, $sortDir)
    {
        $this->sortBy = $sortBy;
        $this->sortDir = $sortDir;
    }

    // Raw Queries the database and returns an associative array
    // For debugging only
    public function query($sql)
    {
        if($this->debug) {
            $res = $this->db->query($sql);
            if(is_object($res)) {
                return $res->fetchAll(PDO::FETCH_ASSOC);
            }
            $err = $this->db->errorInfo();
            $this->logError($err[2]);
        }
        return null;
    }

    // Translates the * wildcard to SQL % wildcard
    private function parseWildcard($query)
    {
        return str_replace('*', '%', $query . '*');
    }

    // Trims input
    private function trimField(&$value, &$key)
    {
        $value = trim($value);
        $value = trim($value, '.');
    }

    // Trims input
    private function trimField2(&$value, &$key)
    {
        $value = trim($value);
        $value = trim($value, '.');
    }

    private function ucwordss($str) {
        $lowerCase = array('OF');
        $out = "";
        foreach (explode(" ", $str) as $word) {
            if(in_array($word, $lowerCase)) {
                $out .= strtolower($word) . ' ';
            }
            else if(strlen($word) > 4 || metaphone($word) != $word) {
                $out .= strtoupper($word[0]) . substr(strtolower($word), 1) . " ";
            }
            else {
                $out .= $word . " ";
            }
        }
        return rtrim($out);
    }

    // Imports data from ^ and \n delimited file of format:
    public function importVistaData($file)
    {
        $rawdata = file($file);
        $count = 0;

        foreach($rawdata as $line) {
            $t = explode("^", $line);
            array_walk($t, array($this, 'trimField'));

//            $tmpName = explode(',', $t[0]);
            $lname = isset($t[0]) ? $t[0] : null;
//            $tmp = explode(' ', $tmpName[1]);
            $fname = isset($t[1]) ? $t[1] : null;
            $midIni = isset($t[2]) ? $t[2] : null;
            $email = isset($t[93]) ? $t[93] : null;
            $phone = isset($t[5]) ? $t[5] : null;
            $pager = isset($t[6]) ? $t[6] : null;
            $roomNum = isset($t[7]) ? str_replace('-', '', $t[7]) : null;
//            $title = $t[1] ? $this->ucwordss($t[1]) : null;
//            $service = $t[5] ? $this->ucwordss($t[5]) : null;
            $title = isset($t[3]) ? $t[3] : null;
            $service = isset($t[4]) ? $t[4] : null;
            $mailcode = isset($t[98]) ? $t[98] : null;
            $loginName = isset($t[97]) ? $t[97] : null;

            $id = md5(strtoupper($lname).strtoupper($fname).strtoupper($midIni));
            $this->users[$id]['lname'] = isset($this->users[$id]['lname']) ? $this->users[$id]['lname'] : $lname;
            $this->users[$id]['fname'] = isset($this->users[$id]['fname']) ? $this->users[$id]['fname'] : $fname;
            $this->users[$id]['midIni'] = $midIni;
            $this->users[$id]['email'] = isset($this->users[$id]['email']) ? $this->users[$id]['email'] : $email;
            $this->users[$id]['phone'] = isset($this->users[$id]['phone']) ? $this->users[$id]['phone'] : $phone;
            $this->users[$id]['pager'] = $pager;
            $this->users[$id]['roomNum'] = $roomNum;
            $this->users[$id]['title'] = isset($this->users[$id]['title']) ? $this->users[$id]['title'] : $title;
            $this->users[$id]['service'] = isset($this->users[$id]['service']) ? $this->users[$id]['service'] : $service;
            $this->users[$id]['mailcode'] = $mailcode;
            $this->users[$id]['loginName'] = isset($this->users[$id]['loginName']) ? $this->users[$id]['loginName'] : $loginName;
            $this->users[$id]['source'] = 'vista';
            echo "Grabbing data for $lname, $fname\n";
            $count++;

            if($count > 100) {
                $this->importData();
                $count = 0;
            }
        }
        $this->importData(); // import any remaining entries
    }

    // Imports data from \t and \n delimited file of format:
    // Name	Business Phone	Description	Modified	E-Mail Address	User Logon Name
    public function importADData($file)
    {
        $rawdata = file_get_contents($file);
        $rawdata = explode("\r\n", $rawdata);

        // workaround for csvde inconsistency
        $rawheaders = trim(array_shift($rawdata));
        $headers = explode(',', $rawheaders);
        $idx = 0;
        $csvdeIdx = array();
        foreach($headers as $header) {
            $csvdeIdx[$header] = $idx;
            $idx++;
        }
/*
        if($idx != 9) {
//            file_put_contents('Z:\phonebook\error.txt', 'Error: AD export');
            return 0;
        }*/

        $count = 0;

        foreach($rawdata as $line) {
            $t = $this->splitWithEscape($line);
//            print_r($t);
//            $t = explode("\t", $line);
            array_walk($t, array($this, 'trimField2'));

//            $tmp = explode(',', $t[0]);
            $lname = trim($t[$csvdeIdx['sn']]);
//            $tmp2 = explode(' ', trim($tmp[1]));
            $fname = trim($t[$csvdeIdx['givenName']]);
            $midIni = trim($t[$csvdeIdx['initials']]);
            $email = isset($csvdeIdx['mail']) && isset($t[$csvdeIdx['mail']]) ? $t[$csvdeIdx['mail']] : null;
            $phone = $t[$csvdeIdx['telephoneNumber']] ? $t[$csvdeIdx['telephoneNumber']] : null;
            $pager = isset($t[94]) ? $t[94] : null;
            $roomNum = $t[$csvdeIdx['physicalDeliveryOfficeName']] ? $t[$csvdeIdx['physicalDeliveryOfficeName']] : null;
            $title = $t[$csvdeIdx['title']] ? $t[$csvdeIdx['title']] : null;
            $service = $t[$csvdeIdx['description']] ? $t[$csvdeIdx['description']] : null;
            $mailcode = isset($t[98]) ? $t[98] : null;
            $loginName = $t[$csvdeIdx['sAMAccountName']] ? $t[$csvdeIdx['sAMAccountName']] : null;
//            $objectGUID = isset($t[$csvdeIdx['objectGUID']]) ? $t[$csvdeIdx['objectGUID']] : null;
            $objectGUID = null;
            $mobile = isset($csvdeIdx['mobile']) && isset($t[$csvdeIdx['mobile']]) ? $t[$csvdeIdx['mobile']] : null;
            $userAccountControl = $t[$csvdeIdx['userAccountControl']] ? $t[$csvdeIdx['userAccountControl']] : null;
            $domain = $t[$csvdeIdx['DN']] ? $t[$csvdeIdx['DN']] : null;
            $domain = parseDomain($domain);
            $domain = $t[$csvdeIdx['DN']] ? $t[$csvdeIdx['DN']] : null;
            $domain = $this->parseDomain($domain);

            $id = md5(strtoupper($lname).strtoupper($fname).strtoupper($midIni));
            if($lname != '') {
                $this->users[$id]['lname'] = $lname;
                $this->users[$id]['fname'] = $fname;
                $this->users[$id]['midIni'] = $midIni;
                $this->users[$id]['email'] = $email;
                $this->users[$id]['phone'] = $phone;
                $this->users[$id]['pager'] = $pager;
                $this->users[$id]['roomNum'] = $roomNum;
                $this->users[$id]['title'] = $title;
                $this->users[$id]['service'] = $service;
                $this->users[$id]['mailcode'] = $mailcode;
                $this->users[$id]['loginName'] = $loginName;
                $this->users[$id]['objectGUID'] = $objectGUID;
                $this->users[$id]['userAccountControl'] = $userAccountControl;
                $this->users[$id]['domain'] = $domain;
                $this->users[$id]['mobile'] = $mobile;
                $this->users[$id]['domain'] = $domain;
                $this->users[$id]['source'] = 'ad';
                echo "Grabbing data for $lname, $fname\n";
                $count++;
            }
            else {
                echo "{$loginName} probably not a user, skipping.\n";
            }

            if($count > 100) {
                $this->importData();
                $count = 0;
            }
        }
        $this->importData(); // import any remaining entries

        // Mark accounts not updated in the past 14 days as deleted
        //$timeLimit = strtotime('14 days ago');
        //$sql = "UPDATE employee SET deleted=1
        //                WHERE lastUpdated < :timeLimit
        //					AND lastUpdated > 0";

        //$pq3 = $this->db->prepare($sql);
        //$pq3->bindParam(':timeLimit', $timeLimit);
        //$pq3->execute();
    }

    // Imports data from \t and \n delimited file of format:
    // Lname\t Fname Mid_Initial\t Email\t Phone\t Pager\t Room#\t Title\t Service\t MailCode\n
    public function importData()
    {
        $time = time();
        $sql = "INSERT INTO employee (userName, lastName, firstName, middleName, phoneticFirstName, phoneticLastName, domain, lastUpdated)
                    VALUES (:loginName, :lname, :fname, :midIni, :phoneticFname, :phoneticLname, :domain, :lastUpdated)";

        $pq = $this->db->prepare($sql);
        $count = 0;

        $userKeys = array_keys($this->users);

        foreach($userKeys as $key) {
            $phoneticFname = metaphone($this->users[$key]['fname']);
            $phoneticLname = metaphone($this->users[$key]['lname']);

            $sql = "SELECT SQL_NO_CACHE * FROM employee WHERE username = :loginName";
            $pq2 = $this->db->prepare($sql);
            $pq2->bindParam(':loginName', $this->users[$key]['loginName']);
            $pq2->execute();
            $res = $pq2->fetchAll();

            if(count($res) > 0) {
                echo "Updating data for {$this->users[$key]['lname']}, {$this->users[$key]['fname']} \n";

                $sql = "INSERT INTO employee_data (empUID, indicatorID, data, author)
                            VALUES (:empUID, :indicatorID, :data, 'system')
                            ON DUPLICATE KEY UPDATE data=:data";

                $pq3 = $this->db->prepare($sql);
                $pq3->bindParam(':empUID', $res[0]['empUID']);
                $id = 6;
                $pq3->bindParam(':indicatorID', $id);
                $pq3->bindParam(':data', $this->users[$key]['email']);
                $pq3->execute();

                $pq3 = $this->db->prepare($sql);
                $pq3->bindParam(':empUID', $res[0]['empUID']);
                $id = 5;
                $pq3->bindParam(':indicatorID', $id);
                $pq3->bindParam(':data', $this->users[$key]['phone']);
                $pq3->execute();

                $pq3 = $this->db->prepare($sql);
                $pq3->bindParam(':empUID', $res[0]['empUID']);
                $id = 8;
                $pq3->bindParam(':indicatorID', $id);
                $pq3->bindParam(':data', $this->users[$key]['roomNum']);
                $pq3->execute();

                $pq3 = $this->db->prepare($sql);
                $pq3->bindParam(':empUID', $res[0]['empUID']);
                $id = 23;
                $pq3->bindParam(':indicatorID', $id);
                $pq3->bindParam(':data', $this->users[$key]['title']);
                $pq3->execute();

                // don't store mobile # if it's the same as the primary phone #
                if($this->users[$key]['phone'] != $this->users[$key]['mobile']) {
                	$pq3 = $this->db->prepare($sql);
                	$pq3->bindParam(':empUID', $res[0]['empUID']);
                	$id = 16;
                	$pq3->bindParam(':indicatorID', $id);
                	$pq3->bindParam(':data', $this->users[$key]['mobile']);
                	$pq3->execute();
                }

                $pq3 = $this->db->prepare($sql);
                $pq3->bindParam(':empUID', $res[0]['empUID']);
                $id = -1;
                $pq3->bindParam(':indicatorID', $id);
                $pq3->bindParam(':data', $this->users[$key]['domain']);
                $pq3->execute();

                $pq3 = $this->db->prepare($sql);
                $pq3->bindParam(':empUID', $res[0]['empUID']);
                $id = -2;
                $pq3->bindParam(':indicatorID', $id);
                $poaExempt = $this->users[$key]['userAccountControl'] & 262144 ? 'No' : 'Yes';
                $pq3->bindParam(':data', $poaExempt);
                $pq3->execute();
                $sql = "UPDATE employee SET lastName=:lname,
                                firstName=:fname,
                                middleName=:midIni,
                                phoneticFirstName=:phoneticFname,
                                phoneticLastName=:phoneticLname,
                				domain=:domain,
                                lastUpdated=:lastUpdated,
                				deleted = 0
                            WHERE username=:userName";

                $pq3 = $this->db->prepare($sql);
                $pq3->bindParam(':userName', $this->users[$key]['loginName']);
                $pq3->bindParam(':lname', $this->users[$key]['lname']);
                $pq3->bindParam(':fname', $this->users[$key]['fname']);
                $pq3->bindParam(':midIni', $this->users[$key]['midIni']);
                $pq3->bindParam(':phoneticFname', $phoneticFname);
                $pq3->bindParam(':phoneticLname', $phoneticLname);
                $pq3->bindParam(':domain', $this->users[$key]['domain']);
                $pq3->bindParam(':lastUpdated', $time);
                $pq3->execute();
            }
            else {
                $pq->bindParam(':loginName', $this->users[$key]['loginName']);
                $pq->bindParam(':lname', $this->users[$key]['lname']);
                $pq->bindParam(':fname', $this->users[$key]['fname']);
                $pq->bindParam(':midIni', $this->users[$key]['midIni']);
                //$pq->bindParam(':email', $this->users[$key]['email']);
                //$pq->bindParam(':phone', $this->users[$key]['phone']);
                //$pq->bindParam(':pager', $this->users[$key]['pager']);
                //$pq->bindParam(':roomNum', $this->users[$key]['roomNum']);
                //$pq->bindParam(':title', $this->users[$key]['title']);
                //$pq->bindParam(':service', $this->users[$key]['service']);
                //$pq->bindParam(':mailcode', $this->users[$key]['mailcode']);
                $pq->bindParam(':phoneticFname', $phoneticFname);
                $pq->bindParam(':phoneticLname', $phoneticLname);
                //$pq->bindParam(':source', $this->users[$key]['source']);
                $pq->bindParam(':domain', $this->users[$key]['domain']);
                $pq->bindParam(':lastUpdated', $time);

                $pq->execute();
                echo "Inserting data for {$this->users[$key]['lname']}, {$this->users[$key]['fname']} : " . $pq->errorCode() . "\n";

                $lastEmpUID = $this->db->lastInsertId();
                if($pq->errorCode() != '00000') {
                    print_r($pq->errorInfo());
                }

                // prioritize adding email to DB
                $sql = "INSERT INTO employee_data (empUID, indicatorID, data, author)
                            VALUES (:empUID, :indicatorID, :data, 'system')
                            ON DUPLICATE KEY UPDATE data=:data";

                $pq3 = $this->db->prepare($sql);
                $pq3->bindParam(':empUID', $lastEmpUID);
                $id = 6;
                $pq3->bindParam(':indicatorID', $id);
                $pq3->bindParam(':data', $this->users[$key]['email']);
                $pq3->execute();
                $count++;
            }
            unset($this->users[$key]);
        }

        echo "Cleanup... ";
// TODO: do some clean up
        echo "... Done.\n";

        echo "Total: $count";
    }

    // custom
    public function importExtra($lname, $fname, $midIni, $email, $phone, $pager, $roomNum, $title, $service, $mailcode, $loginName)
    {
        $sql = "SELECT SQL_NO_CACHE * FROM Employee WHERE loginName = :loginName";
        $pq2 = $this->db->prepare($sql);
        $pq2->bindParam(':loginName', $loginName);
        $pq2->execute();
        $res = $pq2->fetchAll();

        if(count($res) > 0) {
            echo "Ignoring data for {$lname}, {$fname} : Already in database. \n";
            return true;
        }

        $sql = "INSERT INTO Employee (Lname, Fname, Mid_Initial, Email, Phone, Pager, RoomNumber,
                            Title, Service, MailCode, PhoneticFname, PhoneticLname, LoginName, source)
                            VALUES (:lname, :fname, :midIni, :email, :phone, :pager, :roomNum,
                            :title, :service, :mailcode, :phoneticFname, :phoneticLname, :loginName, :source)";
        $pq = $this->db->prepare($sql);
        $count = 0;

        $phoneticFname = metaphone($fname);
        $phoneticLname = metaphone($lname);
        $tmp = 'extra';
        $pq->bindParam(':lname', $lname);
        $pq->bindParam(':fname', $fname);
        $pq->bindParam(':midIni', $midIni);
        $pq->bindParam(':email', $email);
        $pq->bindParam(':phone', $phone);
        $pq->bindParam(':pager', $pager);
        $pq->bindParam(':roomNum', $roomNum);
        $pq->bindParam(':title', $title);
        $pq->bindParam(':service', $service);
        $pq->bindParam(':mailcode', $mailcode);
        $pq->bindParam(':phoneticFname', $phoneticFname);
        $pq->bindParam(':phoneticLname', $phoneticLname);
        $pq->bindParam(':loginName', $loginName);
        $pq->bindParam(':source', $tmp);

        $pq->execute();
        echo "Inserting data for {$this->users[$key]['lname']}, {$this->users[$key]['fname']} : " . $pq->errorCode() . "\n";
        if($pq->errorCode() != '00000') {
            print_r($pq->errorInfo());
        }

        echo "Inserted Extra: $lname, $fname";
    }

    // Updates phonetic cache
    public function updatePhoneticNames()
    {
        $sql = "SELECT SQL_NO_CACHE * FROM {$this->tableName}";

        $res = $this->db->query($sql)->fetchAll(PDO::FETCH_ASSOC);
        echo 'Generating phonetic cache...';

        foreach($res as $emp) {
            $pFirst = metaphone($emp['Fname']);
            $pLast = metaphone($emp['Lname']);
            $sql = "UPDATE {$this->tableName} SET PhoneticFname = '$pFirst' WHERE EmpID = {$emp['EmpID']}";
            $this->db->query($sql);
            $sql = "UPDATE {$this->tableName} SET PhoneticLname = '$pLast' WHERE EmpID = {$emp['EmpID']}";
            $this->db->query($sql);
        }
    }

    // Clean up all wildcards
    private function cleanWildcards($input) {
        $input = preg_replace('/\*+/i', '*', $input);
        $input = preg_replace('/(\*\s\*)+/i', '', $input);
        return $input;
    }

    // workaround for excel
    // author: tajhlande at gmail dot com
    private function splitWithEscape ($str, $delimiterChar = ',', $escapeChar = '"') {
        $len = strlen($str);
        $tokens = array();
        $i = 0;
        $inEscapeSeq = false;
        $currToken = '';
        while ($i < $len) {
            $c = substr($str, $i, 1);
            if ($inEscapeSeq) {
                if ($c == $escapeChar) {
                    // lookahead to see if next character is also an escape char
                    if ($i == ($len - 1)) {
                        // c is last char, so must be end of escape sequence
                        $inEscapeSeq = false;
                    } else if (substr($str, $i + 1, 1) == $escapeChar) {
                        // append literal escape char
                        $currToken .= $escapeChar;
                        $i++;
                    } else {
                        // end of escape sequence
                        $inEscapeSeq = false;
                    }
                } else {
                    $currToken .= $c;
                }
            } else {
                if ($c == $delimiterChar) {
                    // end of token, flush it
                    array_push($tokens, $currToken);
                    $currToken = '';
                } else if ($c == $escapeChar) {
                    // begin escape sequence
                    $inEscapeSeq = true;
                } else {
                    $currToken .= $c;
                }
            }
            $i++;
        }
        // flush the last token
        array_push($tokens, $currToken);
        return $tokens;
    }

    private function parseDomain($adPath) {
    	$dc = '';
    	$dcSrc = explode(',', $adPath);
    	foreach($dcSrc as $adElement) {
    		if(strpos($adElement, 'DC=') !== false) {
    			$dc .= substr($adElement, 3) . '.';
    		}
    	}
    	$dc = trim($dc, '.');

    	switch($dc) {
    		case 'domain.exmaple.com':
    			return 'DOMAIN';
    		default:
    			return $dc;
    	}
    }
}
