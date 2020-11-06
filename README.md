# Camera Color Correction Toolbox

A toolbox to calculate the optimal color correction matrix that maps the camera responses to the target values.

Following color correction models are supported:

* Linear transformation
* Polynomial regression
* Root-polynomial regression

MATLAB version R2018b or higher with Image Processing Toolbox is **recommended** in order to implement [images.roi](https://www.mathworks.com/help/images/roi-based-processing.html) object. But for other versions the normal [rectangle](https://www.mathworks.com/help/matlab/ref/rectangle.html) function works well too. Optimization Toolbox is **required**.

# Demo

<img src="demo/screenshot.gif">

* This gif is only for demonstration purpose. The source image suffered from lots of color degradation, that is why the result looks very bad :joy:
* Please see `/demo/` folder for more detailed usage guides.

# References

1. Hong, Guowei, M. Ronnier Luo, and Peter A. Rhodes. "A study of digital camera colorimetric characterization based on polynomial modeling." *Color Research & Application: Endorsed by Inter‐Society Color Council, The Colour Group (Great Britain), Canadian Society for Color, Color Science Association of Japan, Dutch Society for the Study of Color, The Swedish Colour Centre Foundation, Colour Society of Australia, Centre Français de la Couleur* 26.1 (2001): 76-84.
2. Finlayson, Graham D., Michal Mackiewicz, and Anya Hurlbert. "Color correction using root-polynomial regression." *IEEE Transactions on Image Processing* 24.5 (2015): 1460-1470.

# License

Copyright 2019 Qiu Jueqin

Licensed under [MIT](http://opensource.org/licenses/MIT).
