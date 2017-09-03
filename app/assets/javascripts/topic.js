var picUpLoadButton = document.querySelector('.js-picUpLoadButton');
var previewImg = document.querySelector('.js-previewPhoto');

picUpLoadButton && picUpLoadButton.addEventListener('change', function (e) {
  var file = e.target.files[0];
  var reader = new FileReader();

  previewImg.classList.add('is-show');

  reader.onload = (function(file) {
    return function(e) {
      previewImg.src = e.target.result;
    };
  })(file);
  reader.readAsDataURL(file);
});


var textArea = document.querySelector('.js-text-area');
var textCounter = document.querySelector('.js-count-text');

var countUP = function() {
  var len = textArea.value.length;
  if(len > 140) textCounter.style.color = "#f00";
  else textCounter.style.color = "";
  textCounter.textContent = len;
};

textArea && (function () {
  countUP();
  textArea.addEventListener('keyup', countUP);
  textArea.addEventListener('keydown', countUP);
})();