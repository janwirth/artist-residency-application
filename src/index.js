import './main.css';
import * as canvas from 'elm-canvas'
import { Elm } from './Main.elm';
import * as serviceWorker from './serviceWorker';
import {Player, Transport, Loop, AutoFilter, FFT, Volume} from 'tone'
import Intense from '@tholman/intense-images'

const fft = new FFT(128)

const onHide = fn =>
    document.addEventListener('visibilitychange', () => fn(document.visibilityState == 'visible'))

class ScrollObserver extends HTMLElement {
    connectedCallback() {
            // https://stackoverflow.com/questions/2481350/how-to-get-scrollbar-position-with-javascript
        const redAndEmit = () =>
             {
                 const total = document.body.clientHeight
                 const visible = window.outerHeight
                 const maxScroll = total - visible
                 const scroll = window.scrollY
                 const detail = Math.min(scroll / maxScroll, 1)
                 const dispatch = () => this.dispatchEvent(new CustomEvent('scrollPct', {detail}))
                 window.requestAnimationFrame(dispatch)
             }
        document.addEventListener('scroll', redAndEmit)
    }
}

class AudioInstallation extends HTMLElement {

    connectedCallback() {
        this.setAttribute('state', 'not-started')
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
            setLevels(JSON.parse(newValue))
        }
        if (name == 'state' ) {
            const startedPlaying =
                ((oldValue == 'not-started') || (oldValue == 'paused')) && newValue == 'playing'
            if (startedPlaying) {
                // setLevels(this.levels)
                Transport.start()
                this.followFft()

            }
            const stoppedPlaying =
                (oldValue == 'playing') && newValue == 'paused'
            if (stoppedPlaying) {
                this.stopFft()
                Transport.stop()
                players.forEach(({player}) => player.stop())
            }
        }
    }
}

class IntenseImage extends HTMLElement {
    connectedCallback() {
        Intense(this.children[0])
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

const setLevels = ({drums, melody}) => players.forEach(({track, volume}) => {
    if (buses.drums.indexOf(track) > -1) {
        volume.volume.value = getVolume(drums)
    }
    if (buses.melody.indexOf(track) > -1) {
        volume.volume.value = getVolume(melody)
    }
})

var autoFilter = new AutoFilter("4n").toMaster().start();

window.customElements.define('factory-beat-player', AudioInstallation )
window.customElements.define('intense-image', IntenseImage )
window.customElements.define('scroll-observer', ScrollObserver )

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

const players = tracks.map(track => {
    const volume = new Volume(-12)
    const player = new Player(`/soundtrack/${track}.mp3`) //.connect(autoFilter)
    player.connect(volume)
    volume.volume.value = -20
    volume.toMaster()
    if (tracksToFollow.indexOf(track) > -1) {
        volume.connect(fft)
    }
    // player.sync().start(0)
    return {player, track, volume}
})

const loop = new Loop(time => {
    players.forEach(({player}) => player.restart())
    // Transport.start()
}, trackLength)
loop.start(0)


// setTimeout(() => Transport.start(), 500)

Elm.Main.init({
  node: document.getElementById('root')
});

// If you want your app to work offline and load faster, you can change
// unregister() to register() below. Note this comes with some pitfalls.
// Learn more about service workers: https://bit.ly/CRA-PWA
serviceWorker.unregister();


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

