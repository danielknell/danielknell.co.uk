"use strict";
var footer = document.querySelector('footer');

Array.from(document.querySelectorAll('li a')).forEach(function(element) {
  let action = element.querySelector('p').textContent
    , service = element.querySelector('h2').textContent
    , text = `${action} on ${service}`
    ;

  element.addEventListener('mouseover', e => footer.textContent = text);
  element.addEventListener('mouseout', e => footer.textContent = "");
});