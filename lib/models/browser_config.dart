import 'package:flutter/material.dart';

class BrowserConfig {
  // UI Colors
  static const Color primaryColor = Color(0xFF1A237E); // Dark Blue
  static const Color backgroundColor = Color(0xFF0D0D1A); // Very Dark
  static const Color cardColor = Color(0xFF1A1A2E); // Dark
  static const Color textColor = Color(0xFFFFFFFF); // White
  static const Color accentColor = Color(0xFF4CAF50); // Green
  static const Color errorColor = Color(0xFFFF6B6B); // Red
  static const Color warningColor = Color(0xFFFF9800); // Orange

  // App Constants
  static const String appName = 'Movies';
  static const String defaultHomepage = 'https://onlyflix.to/';
  static const String remoteAllowlistUrl =
      'https://raw.githubusercontent.com/sonoou/movies_store/refs/heads/main/allowlist.txt';

  // Allowlist domains extracted from list
  static const List<String> defaultAllowlist = [
    '1shows.org',
    '2flix.lol',
    'anifast.co',
    'aniwaves.ru',
    'azmovies.to',
    'bcine.ru',
    'bingewatchtv.cyou',
    'bingr.one',
    'boredflix.tv',
    'cinebest.net',
    'cinehd.vc',
    'cinejoy.to',
    'coreflix.tv',
    'dulo.gd',
    'fboxtv.bz',
    'flixbaba.info',
    'flixeo.tv',
    'flixer.su',
    'flixnova.cyou',
    'hdtoday.sc',
    'himovies.ac',
    'hydrahd.info',
    'moviekids.bz',
    'movieplex.online',
    'moviesjoy.bz',
    'myflixer.sc',
    'myflixerz.org',
    'nepu.io',
    'netprime.cx',
    'nightflix.us',
    'novahd.cc',
    'noxx.to',
    'oflix.st',
    'onlyflix.to',
    'pantyflix.com',
    'pressplayz.to',
    'redflix.one',
    'rentry.co',
    'ridomovies.tv',
    'ww4.seeflix.to',
    'shiopa.com',
    'skyflix.cx',
    'skyflix.cx/movies',
    'smashystream.xyz',
    'soapy.to',
    'solarmovie2.com',
    'streamex.net',
    'streamingunity.dog',
    'theflixbay.com',
    'vidflix.live',
    'vidplay.top',
    'yesmovies.ag',
    'yomi.to',
    'zetmoon.live',
  ];

  // Ad domains list to block at network level
  static const List<String> adDomains = [
    'doubleclick.net',
    'googleadservices.com',
    'googlesyndication.com',
    'google-analytics.com',
    'adservice.google.com',
    'facebook.com/tr',
    'connect.facebook.net',
    'adnxs.com',
    'adsrvr.org',
    'amazon-adsystem.com',
    'scorecardresearch.com',
    'outbrain.com',
    'taboola.com',
    'criteo.com',
    'casalemedia.com',
    'rubiconproject.com',
    'pubmatic.com',
    'adzerk.net',
    'adform.net',
    'adsafeprotected.com',
    'moatads.com',
    'openx.net',
    'indexexchange.com',
    'improvedigital.com',
    'sovrn.com',
    'yieldmo.com',
    'bidswitch.net',
  ];

  // URL patterns to block
  static const List<String> adUrlPatterns = [
    '/ad/',
    '/ads/',
    '/banner/',
    '/sponsored/',
    '/promo/',
    '/tracking/',
    '/analytics/',
    '?ad=',
    '&ad=',
    'utm_',
  ];
}
