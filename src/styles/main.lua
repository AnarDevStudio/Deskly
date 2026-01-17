require 'imlib2'

local img = imlib2.image.load("/home/kullanici/Pictures/logo.png")
imlib2.image.render(img, 100, 100)
