# PWA in Rails

Notes in creating a Progressive Web App in Rails from scratch. I am using
Rails 6.0.0 RC 1 but this should all work in Rails 5 as well.
This isn't (currently) intended as a tutorial.

References:

* [Google Web Fundamentals documentation](https://developers.google.com/web/fundamentals)
* [Easy PWAs the Rails Way by John Beatty](https://johnbeatty.co/2019/01/08/easy-pwas-the-rails-way/)
* [Webpacker Javascript in Rails 6 (Go Rails)](https://gorails.com/episodes/webpacker-javascript-in-rails-6)

## Install 

```bash
rails new pwa -T
```

and add `rspec-rails` to `Gemfile`.

Add this to `app/application.rb` to prevent creation of `view` specs:

```ruby
config.generators do |g|
  g.test_framework :rspec, view_specs: false
end
```

## Manifest

From [Google Web Fundamentals - Web App Manifext:](https://developers.google.com/web/fundamentals/web-app-manifest/)

> The web app manifest is a simple JSON file that tells the browser about your
> web application and how it should behave when 'installed' on the user's
> mobile device or desktop. Having a manifest is required by Chrome to show
> the Add to Home Screen prompt.

From "Easy PWAs the Rails Way", add the following lines to the `<head>` section in `app/views/layouts/application.html.erb`:

```html
<!-- Lighthouse Details -->
<link rel="manifest" href="/manifest.json">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="theme-color" content="#C50001"/>
```

The `manifest` line defines the location of the Web App Manifest file. I think
that it applies to files in the same directory or subdirectories so it needs
to be in the top level to work for the whole application.

The `viewport` line is to make the app display correctly on small screens.

I'm not entirely sure whether the `theme-color` line is required.

## Service Manager

From [Google Web Fundamentals - Service Worker](https://developers.google.com/web/fundamentals/primers/service-workers/)

> A service worker is a script that your browser runs in the background,
> separate from a web page, opening the door to features that don't need a
> web page or user interaction.

The service worker needs to be registered in Javascript by adding this in
Webpacker:

```javascript
if (navigator.serviceWorker) {
  navigator.serviceWorker.register('/service-worker.js', { scope: './' })
    .then(function(reg) {
      console.log('[Companion]', 'Service worker registered!');
      console.log(reg);
    });
}
```

I will probably move it somewhere else but for the moment I have put it at the
end of `app/javascript/packs/application.js`.

## Service Worker controller

The "Easy PWAs the Rails Way" shows two places to put the manifest and service
worker files. I am using the second method and creating a controller.

```bash
rails g controller ServiceWorker service_worker manifest
mv app/views/service_worker/manifest.html.erb app/views/service_worker/manifest.json.erb
mv app/views/service_worker/service_worker.html.erb app/views/service_worker/service_worker.js.erb
```

To avoid Rails causing problems attempting to protect from forgery, add:

```ruby
protect_from_forgery except: :service_worker
```

to `app/controllers/service_worker_controller.rb`.

Replace `manifest.json.erb` with

```json
{
  "short_name": "PWA",
  "name": "A test Progressive Web App",
  "icons": [
    {
      "src": "<%= asset_path('icon_192.png') %>",
      "type": "image/png",
      "sizes": "192x192"
    },
    {
      "src": "<%= asset_path('icon_512.png') %>",
      "type": "image/png",
      "sizes": "512x512"
    }
  ],
  "start_url": "<%= root_path %>",
  "background_color": "#fff",
  "display": "standalone",
  "scope": "<%= root_path %>",
  "theme_color": "#000"
}
```

and `service_worker.js.erb` with

```javascript
var CACHE_VERSION = 'v1';
var CACHE_NAME = CACHE_VERSION + ':sw-cache-';

function onInstall(event) {
  console.log('[Serviceworker]', "Installing!", event);
  event.waitUntil(
    caches.open(CACHE_NAME).then(function prefill(cache) {
      return cache.addAll([
        '<%= asset_pack_path 'application.js' %>',
        '<%= asset_pack_path 'application.css' %>',
      ]);
    })
  );
}

function onActivate(event) {
  console.log('[Serviceworker]', "Activating!", event);
  event.waitUntil(
    caches.keys().then(function(cacheNames) {
      return Promise.all(
        cacheNames.filter(function(cacheName) {
          // Return true if you want to remove this cache,
          // but remember that caches are shared across
          // the whole origin
          return cacheName.indexOf(CACHE_VERSION) !== 0;
        }).map(function(cacheName) {
          return caches.delete(cacheName);
        })
      );
    })
  );
}

// Borrowed from https://github.com/TalAter/UpUp
function onFetch(event) {
  event.respondWith(
    // try to return untouched request from network first
    fetch(event.request).catch(function() {
      // if it fails, try to return request from the cache
      return caches.match(event.request).then(function(response) {
        if (response) {
          return response;
        }
        // if not found in cache, return default offline content for navigate requests
        if (event.request.mode === 'navigate' ||
          (event.request.method === 'GET' && event.request.headers.get('accept').includes('text/html'))) {
          console.log('[Serviceworker]', "Fetching offline content", event);
          return caches.match('/offline.html');
        }
      })
    })
  );
}

self.addEventListener('install', onInstall);
self.addEventListener('activate', onActivate);
self.addEventListener('fetch', onFetch);
```

Explanations of these files to follow but for the moment they are just copied
from "Easy PWAs the Rails Way".