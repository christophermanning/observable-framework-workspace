// See https://observablehq.com/framework/config for documentation.
export default {
  // The project’s title; used in the sidebar and webpage titles.
  title: "Workspace",

  // Content to add to the head of the page, e.g. for a favicon:
  head: '',

  // The path to the source root.
  root: "src",

  // Some additional configuration options and their defaults:
  // theme: "default", // try "light", "dark", "slate", etc.
  // header: "", // what to show in the header (HTML)
  footer: () => {
    let date = new Date().toLocaleString("en-US", {timeZoneName: "short"})
    return `
<div class="small">
<p>
<b>Created By</b> <a href="https://www.christophermanning.org" target="_blank">Christopher Manning</a> |
<b>Source Code</b> <a href="https://github.com/christophermanning/observable-framework-workspace" target="_blank">GitHub</a>
</p>
Built with <a href="https://observablehq.com/" target="_blank">Observable</a> on <a title="${date}">${date}</a>.
</div>
  `}, // what to show in the footer (HTML)
  sidebar: true, // whether to show the sidebar
  // toc: true, // whether to show the table of contents
  // pager: false, // whether to show previous & next links in the footer
  // output: "dist", // path to the output root for build
  // search: true, // activate search
  // linkify: true, // convert URLs in Markdown to links
  // typographer: false, // smart quotes and other typographic improvements
  // cleanUrls: true, // drop .html from URLs
};
