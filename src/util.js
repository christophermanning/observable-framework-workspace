import {html} from "npm:htl";

export function link(name, url) {
  return html`<a href="${url}" rel="noreferrer" target="_blank">${name}</a>`
}
