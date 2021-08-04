'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';
const RESOURCES = {
  "sql-wasm.wasm": "ea7edc8cc0702b48cc93bf41e5b6cc61",
"assets/assets/fonts/OpenSans-Regular.ttf": "3ed9575dcc488c3e3a5bd66620bdf5a4",
"assets/assets/fonts/Montserrat-Light.ttf": "409c7f79a42e56c785f50ed37535f0be",
"assets/assets/fonts/Montserrat-Regular.ttf": "ee6539921d713482b8ccd4d0d23961bb",
"assets/assets/fonts/OpenSans-Bold.ttf": "1025a6e0fb0fa86f17f57cc82a6b9756",
"assets/assets/images/brand/logo-horiz-no-subtitle-dark.png": "c424b52d9789844c50efd1841f330016",
"assets/assets/images/brand/logo-vert-no-subtitle.png": "181c34ae51c6053ba9dc18035aac2399",
"assets/assets/images/brand/logo-horiz-no-subtitle.png": "7f2b427acfa0012da79aa7a8251d148b",
"assets/assets/images/brand/logo-horiz-no-subtitle-light.png": "e97bd96b43d96d3d839c0ed9660bf472",
"assets/assets/images/profile/profile_new_user_delete.png": "6eb625030efb33a901a7be4531e015da",
"assets/assets/images/profile/profile_welcome.png": "8ce2b109cbe2aa3155d501be5bc47dba",
"assets/assets/images/profile/profile_new_user_upload.png": "6eb625030efb33a901a7be4531e015da",
"assets/assets/images/profile/profile_add.png": "bb761b58972221c0bb8a330c1be86f3a",
"assets/assets/images/profile/profile_permahills_bg.png": "b4d8f83b6bd7750a64cb305bcf1dd1a0",
"assets/assets/images/profile/profile_new_user_permanent.png": "19cef59765533319b5ab58d665200762",
"assets/assets/images/profile/profile_unlock.png": "bb761b58972221c0bb8a330c1be86f3a",
"assets/assets/images/profile/profile_new_user_payment.png": "968d2e6cb2304669cd61d8f614b960a4",
"assets/assets/images/profile/profile_new_user_private.png": "bb761b58972221c0bb8a330c1be86f3a",
"assets/assets/config/prod.json": "3d6c5819f04179660960f51274c830aa",
"assets/assets/config/dev.json": "3d6c5819f04179660960f51274c830aa",
"assets/AssetManifest.json": "583e734794cb1c08e4b1c8d582c84c70",
"assets/FontManifest.json": "7b2a36307916a9721811788013e65289",
"assets/fonts/MaterialIcons-Regular.otf": "4e6447691c9509f7acdbf8a931a85ca1",
"assets/packages/flutter_dropzone_web/assets/flutter_dropzone.js": "5ee1f285611168cd6df377fd21151aae",
"assets/NOTICES": "6553b4ba9509dc163534f4674109109a",
"icons/Icon-192.png": "59fd8ea25636b975179f03f82cc7b19e",
"icons/Icon-512.png": "92dc660f505d120ed1d92db8ec74943d",
"favicon.png": "9a13599a830ef123989fad7c28d09cc0",
"manifest.json": "a610c0950a2012e01119d0e8a57e3585",
"version.json": "b26a94970f432fb52fa370dac5f6cda1",
"pst.min.js": "4418d27078fa65411dbfc29f909e2ebc",
"main.dart.js": "c7e04c9a33847c71205dd434690acebe",
"sql-wasm.js": "eea55d481cf4aeb2bc2d7c90eec64a25",
"js/arconnect.js": "fcf3565603d187e5050b091f013c4d45",
"index.html": "cc05d5055cdf0e96986e7bcb1c2e3aec",
"/": "cc05d5055cdf0e96986e7bcb1c2e3aec"
};

// The application shell files that are downloaded before a service worker can
// start.
const CORE = [
  "/",
"main.dart.js",
"index.html",
"assets/NOTICES",
"assets/AssetManifest.json",
"assets/FontManifest.json"];
// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});

// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});

// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache.
        return response || fetch(event.request).then((response) => {
          cache.put(event.request, response.clone());
          return response;
        });
      })
    })
  );
});

self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});

// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}

// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
