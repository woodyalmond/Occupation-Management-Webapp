// 서비스 워커 - 푸시 알림 및 오프라인 지원

// 캐시 이름
const CACHE_NAME = 'alarm-app-cache-v1';

// 캐시할 파일 목록
const urlsToCache = [
  '/alarmapp/',
  '/alarmapp/index.html',
  '/alarmapp/main.dart.js',
  '/alarmapp/flutter_service_worker.js',
  '/alarmapp/assets/fonts/MaterialIcons-Regular.otf',
  '/alarmapp/assets/AssetManifest.json',
  '/alarmapp/assets/FontManifest.json',
  '/alarmapp/assets/NOTICES',
  '/alarmapp/icons/Icon-192.png',
  '/alarmapp/icons/Icon-512.png',
  '/alarmapp/icons/Icon-152.png',
  '/alarmapp/icons/Icon-167.png',
  '/alarmapp/icons/Icon-180.png',
  '/alarmapp/icons/splash.png'
];

// 서비스 워커 설치 시 캐시 초기화
self.addEventListener('install', event => {
  console.log('서비스 워커 설치 중...');
  self.skipWaiting(); // 즉시 활성화
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => {
        console.log('파일 캐싱 중...');
        return cache.addAll(urlsToCache);
      })
  );
});

// 서비스 워커 활성화 시 이전 캐시 정리
self.addEventListener('activate', event => {
  console.log('서비스 워커 활성화 중...');
  event.waitUntil(
    caches.keys().then(cacheNames => {
      return Promise.all(
        cacheNames.filter(cacheName => {
          return cacheName !== CACHE_NAME;
        }).map(cacheName => {
          return caches.delete(cacheName);
        })
      );
    }).then(() => {
      console.log('서비스 워커가 클라이언트 요청을 처리할 준비가 되었습니다.');
      return self.clients.claim();
    })
  );
});

// 네트워크 요청 가로채기 및 캐시 응답
self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request)
      .then(response => {
        // 캐시에서 찾으면 캐시 응답 반환
        if (response) {
          return response;
        }
        
        // 캐시에 없으면 네트워크 요청
        return fetch(event.request).then(response => {
          // 유효한 응답이 아니면 그대로 반환
          if (!response || response.status !== 200 || response.type !== 'basic') {
            return response;
          }
          
          // 응답 복제 (스트림은 한 번만 사용 가능)
          const responseToCache = response.clone();
          
          // 응답을 캐시에 저장
          caches.open(CACHE_NAME)
            .then(cache => {
              cache.put(event.request, responseToCache);
            });
            
          return response;
        });
      })
  );
});

// 푸시 알림 수신 처리
self.addEventListener('push', event => {
  console.log('푸시 알림 수신:', event);
  
  let title = '알람 타이머';
  let options = {
    body: '타이머가 완료되었습니다!',
    icon: '/alarmapp/icons/Icon-192.png',
    badge: '/alarmapp/icons/Icon-192.png',
    vibrate: [300, 100, 300, 100, 300, 100, 300],
    tag: 'alarm-notification',
    renotify: true,
    requireInteraction: true,
    actions: [
      {
        action: 'open',
        title: '앱 열기'
      },
      {
        action: 'close',
        title: '닫기'
      }
    ]
  };
  
  // 푸시 데이터가 있으면 사용
  if (event.data) {
    try {
      const data = event.data.json();
      title = data.title || title;
      options.body = data.body || options.body;
    } catch (e) {
      console.error('푸시 데이터 파싱 오류:', e);
    }
  }
  
  event.waitUntil(
    self.registration.showNotification(title, options)
  );
});

// 알림 클릭 처리
self.addEventListener('notificationclick', event => {
  console.log('알림 클릭:', event);
  
  event.notification.close();
  
  if (event.action === 'close') {
    return;
  }
  
  // 앱 열기
  event.waitUntil(
    clients.matchAll({type: 'window'})
      .then(clientList => {
        // 이미 열린 창이 있으면 포커스
        for (const client of clientList) {
          if (client.url.includes('/alarmapp/') && 'focus' in client) {
            return client.focus();
          }
        }
        // 열린 창이 없으면 새 창 열기
        if (clients.openWindow) {
          return clients.openWindow('/alarmapp/');
        }
      })
  );
});

// 백그라운드 동기화 처리
self.addEventListener('sync', event => {
  if (event.tag === 'alarm-sync') {
    console.log('백그라운드 동기화 요청:', event);
    // 여기에 백그라운드 동기화 로직 추가
  }
});

// 주기적 동기화 처리 (iOS에서는 지원되지 않음)
self.addEventListener('periodicsync', event => {
  if (event.tag === 'alarm-periodic-sync') {
    console.log('주기적 동기화 요청:', event);
    // 여기에 주기적 동기화 로직 추가
  }
});

// 메시지 처리 (메인 스레드와 통신)
self.addEventListener('message', event => {
  console.log('메시지 수신:', event.data);
  
  if (event.data && event.data.type === 'SHOW_NOTIFICATION') {
    // 메인 스레드에서 요청한 알림 표시
    self.registration.showNotification('알람 타이머', {
      body: event.data.message || '타이머가 완료되었습니다!',
      icon: '/alarmapp/icons/Icon-192.png',
      badge: '/alarmapp/icons/Icon-192.png',
      vibrate: [300, 100, 300, 100, 300],
      tag: 'alarm-notification',
      renotify: true
    });
  }
  
  // 클라이언트에 응답
  if (event.source) {
    event.source.postMessage({
      type: 'NOTIFICATION_SHOWN',
      success: true
    });
  }
});
