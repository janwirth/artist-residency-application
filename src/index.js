import './main.css';
import * as canvas from 'elm-canvas'
import { Elm } from './Main.elm';
import * as serviceWorker from './serviceWorker';
import Intense from '@tholman/intense-images'
import './audio'


class IntenseImage extends HTMLElement {
    connectedCallback() {
        Intense(this.children[0])
    }
}


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




window.customElements.define('intense-image', IntenseImage )
window.customElements.define('scroll-observer', ScrollObserver )


Elm.Main.init({
  node: document.getElementById('root')
});

// If you want your app to work offline and load faster, you can change
// unregister() to register() below. Note this comes with some pitfalls.
// Learn more about service workers: https://bit.ly/CRA-PWA
serviceWorker.unregister();

