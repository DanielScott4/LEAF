<?php
/*
 * As a work of the United States government, this project is in the public domain within the United States.
 */


 Route::get('/', function () {
     return view('home');
 });

Route::get('/login', function () {
    return view('login');
});

Route::get('/home2', function () {
    return view('home2');
});

Route::get('/welcome', function () {
    return view('welcome');
});

Route::get('/test/{param?}', function ($param = null) {

    return view('subdirectory/subexample', ['param' => $param]);
});
