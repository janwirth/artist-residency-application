import {Player, Transport, Loop, AutoFilter, FFT, Volume} from 'tone'


const fft = new FFT(128)

const onHide = fn =>
    document.addEventListener('visibilitychange', () => fn(document.visibilityState == 'visible'))
class AudioInstallation extends HTMLElement {

    connectedCallback() {
        this.loaded = 0
        this.setAttribute('state', 'not-started')
        const onload = detail => {
            this.event = detail
            setTimeout(() => {
                if (this.event) {
                    this.dispatchEvent(new CustomEvent('bufferloaded', {detail: this.event}))
                    this.event = undefined
                }
            }, 300)
        }
        this.players = makeTracks(onload)
        onHide(visible => {
            const state = this.getAttribute('state')
            if (visible && state == 'playing') {
                this.followFft()
            } else if (!visible) {
                this.stopFft()
            }
        })
    }

    static get observedAttributes() {
        return ['state', 'levels']
    }

    followFft () {
        const redAndEmit = () =>
             {
                 const detail = Array.from(fft.getValue())
                 if (detail[0] !== -Infinity) {
                     const dispatch = () => this.dispatchEvent(new CustomEvent('fft', {detail}))
                     window.requestAnimationFrame(dispatch)
                 }
             }
        this.interval = setInterval(redAndEmit, 40)
    }
    stopFft () {
        clearInterval(this.interval)
    }

    attributeChangedCallback(name, oldValue, newValue) {
        if (name == 'levels') {
            if (this.players) {
                setLevels(this.players)(JSON.parse(newValue))
            } else {
                setTimeout(() => setLevels(this.players)(JSON.parse(newValue)), 100)
            }
        }
        if (name == 'state' ) {
            const startedPlaying =
                ((oldValue == 'not-started') || (oldValue == 'paused')) && newValue == 'playing'
            if (startedPlaying) {
                Transport.start()
                this.followFft()

            }
            const stoppedPlaying =
                (oldValue == 'playing') && newValue == 'paused'
            if (stoppedPlaying) {
                this.stopFft()
                Transport.stop()
                this.players.forEach(({player}) => player.stop())
            }
        }
    }
}
const buses =
    { drums:
        [ 'bass'
        , 'clap-1'
        , 'hat-1'
        , 'kick-1'
        , 'kick-2'
        , 'rim-1'
        , 'rim-2'
        , 'shakers-1'
        , 'wood-1'
        ]
    , melody : [
          'strings-background'
        , 'strings-lead'
    ]

    }

const setLevels = players => ({drums, melody}) => players.forEach(({track, volume}) => {
    if (buses.drums.indexOf(track) > -1) {
        volume.volume.value = getVolume(drums)
    }
    if (buses.melody.indexOf(track) > -1) {
        volume.volume.value = getVolume(melody)
    }
})
window.customElements.define('factory-beat-player', AudioInstallation )
// we set up each track and then play it in a loop
const tracks =
    [ 'bass'
    , 'clap-1'
    , 'hat-1'
    , 'kick-1'
    , 'kick-2'
    , 'rim-1'
    , 'rim-2'
    , 'shakers-1'
    , 'strings-background'
    , 'strings-lead'
    , 'wood-1'
    ]

const tracksToFollow = ['rim-1', 'kick-1', 'clap-1', 'strings-background']
const trackLength = '4m'
const bpm = 93
Transport.bpm.value = bpm
Transport.setLoopPoints(0, "1m")
// Transport.loop = true

const muteVolume = -30
const getVolume = t => muteVolume - (t * muteVolume)

var loaded = 0

const makeTracks = onload => {

    const onloadThen = fn => data => {
        loaded = loaded + 1
        const detail = loaded / tracks.length
        fn(detail)
    }

    const withPlayer = tracks.map(track => {
        const volume = new Volume(-12)
        const player = new Player(`/soundtrack/${track}.mp3`, onloadThen(onload) ) //.connect(autoFilter)
        player.connect(volume)
        volume.volume.value = -20
        volume.toMaster()
        if (tracksToFollow.indexOf(track) > -1) {
            volume.connect(fft)
        }
        return {player, track, volume}
    })

    const loop = new Loop(time => {
        withPlayer.forEach(({player}) => player.restart())
    }, trackLength)

    loop.start(0)

    return withPlayer
}

// optimize perf: when user changes tab

var hidden, visibilityChange; 
if (typeof document.hidden !== "undefined") { // Opera 12.10 and Firefox 18 and later support 
  hidden = "hidden";
  visibilityChange = "visibilitychange";
} else if (typeof document.msHidden !== "undefined") {
  hidden = "msHidden";
  visibilityChange = "msvisibilitychange";
} else if (typeof document.webkitHidden !== "undefined") {
  hidden = "webkitHidden";
  visibilityChange = "webkitvisibilitychange";
}

