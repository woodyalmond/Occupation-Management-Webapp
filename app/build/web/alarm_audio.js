(function () {
  let audioContext = null;
  let gainNode = null;

  function init() {
    const AudioContext = window.AudioContext || window.webkitAudioContext;
    if (!AudioContext) {
      console.warn('Web Audio API is not supported.');
      return false;
    }

    if (!audioContext) {
      audioContext = new AudioContext();
      gainNode = audioContext.createGain();
      gainNode.gain.value = 0.4;
      gainNode.connect(audioContext.destination);
    }

    if (audioContext.state === 'suspended') {
      audioContext.resume();
    }

    return true;
  }

  function playTone(frequency, startOffset, duration) {
    const oscillator = audioContext.createOscillator();
    oscillator.type = 'square';
    oscillator.frequency.value = frequency;
    oscillator.connect(gainNode);
    oscillator.start(audioContext.currentTime + startOffset);
    oscillator.stop(audioContext.currentTime + startOffset + duration);
  }

  function play() {
    if (!init() || !audioContext || !gainNode) {
      return false;
    }

    playTone(880, 0, 0.18);
    playTone(660, 0.28, 0.18);
    playTone(880, 0.56, 0.28);
    return true;
  }

  function vibrate() {
    if (navigator.vibrate) {
      navigator.vibrate([400, 120, 400, 120, 400]);
    }
  }

  window.alarmAudio = {
    init,
    play,
    vibrate,
  };
})();
