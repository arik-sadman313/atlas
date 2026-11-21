import { shortUrl, textWithLinks } from "../../../electron/browser/linktext"
export const shownText = (el: HTMLElement) => textWithLinks(el, shortUrl)
