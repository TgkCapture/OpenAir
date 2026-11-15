package com.tgkcapture.openair

import com.ryanheise.audioservice.AudioServiceActivity

// AudioServiceActivity shares one Flutter engine with the background audio
// service. With a plain FlutterActivity the audio plugin starts a second
// engine and the whole app runs twice.
class MainActivity : AudioServiceActivity()
