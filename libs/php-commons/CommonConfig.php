<?php
/*
 * As a work of the United States government, this project is in the public domain within the United States.
 */

class CommonConfig
{
    public $requestWhitelist = array('doc', 'docx', 'docm', 'dotx', 'dotm',
                                        'csv', 'xls', 'xlsx', 'xlsm', 'xltx', 'xltm', 'xlsb', 'xlam',
                                        'ppt', 'pptx', 'pptm', 'potx', 'potm', 'ppam', 'ppsx', 'ppsm', 'ppts',
                                        'ai', 'eps',
                                        'pdf',
                                        'txt',
                                        'png', 'jpg', 'jpeg', 'bmp', 'gif', 'tif',
                                        'vsd',
                                        'rtf',
                                        'json',
                                        'pub',
                                        'msg', 'ics',
                                        'mht', 'msg', 'xml',
                                        'zip', '7z',
                                    );
    
    public $fileManagerWhitelist = array('doc', 'docx', 'docm', 'dotx', 'dotm',
                                            'csv', 'xls', 'xlsx', 'xlsm', 'xltx', 'xltm', 'xlsb', 'xlam',
                                            'ppt', 'pptx', 'pptm', 'potx', 'potm', 'ppam', 'ppsx', 'ppsm', 'ppts',
                                            'ai', 'eps',
                                            'pdf',
                                            'txt',
                                            'htm', 'html',
                                            'png', 'jpg', 'jpeg', 'bmp', 'gif', 'tif', 'svg',
                                            'vsd',
                                            'rtf',
                                            'json',
                                            'js',
                                            'css',
                                            'pub',
                                            'msg', 'ics',
                                            'mht', 'msg', 'xml',
                                            'zip', '7z',
                                        );

    public $awsSharedConfig = array(
        'region' => 'us-gov-west-1',
        'version' => 'latest',
        'S3' => [
            'bucket' => 'leaf-bucket-vaec-infra'
            //'debug' => 'false' // default is false
        ]
    );
}