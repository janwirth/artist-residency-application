import './main.css';
import { Elm } from './Main.elm';
import * as serviceWorker from './serviceWorker';
import {Player, Transport, Loop, AutoFilter} from 'tone'


class AudioInstallation extends HTMLElement {

    connectedCallback() {
        this.innerHTML = 'hello world'
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
                // autoFilter.rampTo(1, 0)
            }
            const stoppedPlaying =
                (oldValue == 'playing') && newValue == 'paused'
            if (stoppedPlaying) {
                Transport.stop()
                players.forEach(({player}) => player.stop())
                // autoFilter.rampTo(0, 2)
            }
        }
    }
}


var autoFilter = new AutoFilter("4n").toMaster().start();
console.log(autoFilter)

window.customElements.define('factory-beat-player', AudioInstallation )

// we set up each track and then play it in a loop
const tracks = [ 'bass.mp3'
    , 'clap-1.mp3'
    , 'hat-1.mp3'
    , 'kick-1.mp3'
    , 'kick-2.mp3'
    , 'rim-1.mp3'
    , 'rim-2.mp3'
    , 'shakers-1.mp3'
    , 'strings-background.mp3'
    , 'strings-lead.mp3'
    , 'wood-1.mp3'
    ]

const trackLength = '4m'
const bpm = 93
Transport.bpm.value = bpm
Transport.setLoopPoints(0, "1m")
// Transport.loop = true

const players = tracks.map(track => {
    const player = new Player(`/soundtrack/${track}`).connect(autoFilter)
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
