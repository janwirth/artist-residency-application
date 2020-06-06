import './main.css';
import { Elm } from './Main.elm';
import * as serviceWorker from './serviceWorker';
import {Player, Transport, Loop, AutoFilter, FFT} from 'tone'

const fft = new FFT(128)


class AudioInstallation extends HTMLElement {

    connectedCallback() {
        this.setAttribute('state', 'not-started')
    }

    static get observedAttributes() {
        return ['state', 'values', 'position']
    }

    attributeChangedCallback(name, oldValue, newValue) {
        console.log('name', name)
        if (name == 'state' ) {
            const startedPlaying =
                ((oldValue == 'not-started') || (oldValue == 'paused')) && newValue == 'playing'
            if (startedPlaying) {
                Transport.start()
                const redAndEmit = () =>
                     {
                         const detail = Array.from(fft.getValue())
                         if (detail[0] !== -Infinity) {
                             this.dispatchEvent(new CustomEvent('fft', {detail}))
                         }
                     }
                this.interval = setInterval(redAndEmit, 10)
            }
            const stoppedPlaying =
                (oldValue == 'playing') && newValue == 'paused'
            if (stoppedPlaying) {
                clearInterval(this.interval)
                Transport.stop()
                players.forEach(({player}) => player.stop())
            }
        }
    }
}


var autoFilter = new AutoFilter("4n").toMaster().start();

window.customElements.define('factory-beat-player', AudioInstallation )

// we set up each track and then play it in a loop
const tracks = [ 'bass'
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

const tracksToFollow = ['rim-1', 'rim-2', 'lead-background']
const trackLength = '4m'
const bpm = 93
Transport.bpm.value = bpm
Transport.setLoopPoints(0, "1m")
// Transport.loop = true

const players = tracks.map(track => {
    const player = new Player(`/soundtrack/${track}.mp3`).toMaster() //.connect(autoFilter)
    if (tracksToFollow.indexOf(track) > -1) {
        player.connect(fft)
    }
    // player.sync().start(0)
    return {player, track}
    // player.autostart = true
})

const loop = new Loop(time => {
    console.log(time)
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
