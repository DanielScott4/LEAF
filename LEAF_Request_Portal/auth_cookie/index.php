<?php
/*
* As a work of the United States government, this project is in the public domain within the United States.
*/

/*
    Cookie Based Auth
    Date Created: April 30, 2019

*/

include '../globals.php';
include '../Login.php';
include '../db_mysql.php';
include '../db_config.php';

$db_config = new DB_Config();
$config = new Config();
$db = new DB($db_config->dbHost, $db_config->dbUser, $db_config->dbPass, $db_config->dbName);
$db_phonebook = new DB($config->phonedbHost, $config->phonedbUser, $config->phonedbPass, $config->phonedbName);

$login = new Login($db_phonebook, $db);

$protocol = isset($_SERVER['HTTP_X_PROTO']) && $_SERVER['HTTP_X_PROTO'] == 'on' ? 'https://' : 'http://';

if (isset($_COOKIE['REMOTE_USER']) && (!isset(Config::$leafSecure) || Config::$leafSecure == false))
{
    $redirect = '';
    if (isset($_GET['r']))
    {
        $redirect = $protocol . $_SERVER['HTTP_HOST'] . base64_decode($_GET['r']);
    }
    else
    {
        $redirect = $protocol . $_SERVER['HTTP_HOST'] . dirname($_SERVER['PHP_SELF']) . '/../';
    }

    $user = $_COOKIE['REMOTE_USER'];

    // see if user is valid
    $vars = array(':userName' => $user);
    $res = $db_phonebook->prepared_query('SELECT * FROM employee
                                            WHERE userName=:userName
                                            AND deleted=0', $vars);

    if (count($res) > 0)
    {
        $_SESSION['userID'] = $user;
        session_write_close();
        header('Location: ' . $redirect);
        exit();
    }
    else
    {
        // try searching through national database
        $globalDB = new DB(DIRECTORY_HOST, DIRECTORY_USER, DIRECTORY_PASS, DIRECTORY_DB);
        $vars = array(':userName' => $user);
        $res = $globalDB->prepared_query('SELECT * FROM employee
                                          LEFT JOIN employee_data USING (empUID)
                                          WHERE userName=:userName
                                          AND indicatorID = 6
                                                  AND deleted=0', $vars);
        // add user to local DB
        if (count($res) > 0)
        {
            $vars = array(':firstName' => $res[0]['firstName'],
                    ':lastName' => $res[0]['lastName'],
                    ':middleName' => $res[0]['middleName'],
                    ':userName' => $res[0]['userName'],
                    ':phoFirstName' => $res[0]['phoneticFirstName'],
                    ':phoLastName' => $res[0]['phoneticLastName'],
                    ':domain' => $res[0]['domain'],
                    ':lastUpdated' => time(), );
            $db_phonebook->prepared_query('INSERT INTO employee (firstName, lastName, middleName, userName, phoneticFirstName, phoneticLastName, domain, lastUpdated)
                                            VALUES (:firstName, :lastName, :middleName, :userName, :phoFirstName, :phoLastName, :domain, :lastUpdated)
                                            ON DUPLICATE KEY UPDATE deleted=0', $vars);

            $empUID = $db_phonebook->getLastInsertID();

            if ($empUID == 0)
            {
                $vars = array(':userName' => $res[0]['userName']);
                $empUID = $db_phonebook->prepared_query('SELECT empUID FROM employee
                                                          WHERE userName=:userName', $vars)[0]['empUID'];
            }

            $vars = array(':empUID' => $empUID,
                    ':indicatorID' => 6,
                    ':data' => $res[0]['data'],
                    ':author' => 'viaLogin',
                    ':timestamp' => time(),
            );
            $db_phonebook->prepared_query('INSERT INTO employee_data (empUID, indicatorID, data, author, timestamp)
                                            VALUES (:empUID, :indicatorID, :data, :author, :timestamp)
                                            ON DUPLICATE KEY UPDATE data=:data', $vars);

            // redirect as usual
            $_SESSION['userID'] = $res[0]['userName'];
            session_write_close();
            header('Location: ' . $redirect);
            exit();
        }
        else
        {
            header('Location: ' . $protocol . AUTH_URL . '/?r=' . base64_encode($_SERVER['REQUEST_URI']));
        }
    }
}else{
  header('Location: ' . $protocol . AUTH_URL . '/?r=' . base64_encode($_SERVER['REQUEST_URI']));
}
