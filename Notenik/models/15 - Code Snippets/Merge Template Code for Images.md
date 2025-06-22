---
Title: Merge Template Code for Images
Code: <?if "=$imagename$=" ?>
<?if "=$imagecredit$=" ?>
				<figure>
					<img class="img-fluid rounded" src="=$relative$=images/=$imagename&f$=" alt="=$imagealt$=">
				<figcaption class="image-credit">
				image credit:
<?if "imagecreditlink" ?>
					<a href="=$imagecreditlink$=" class="ext-link" target="_blank" rel="noopener">
<?endif?>
						=$imagecredit$=
<?if "imagecreditlink" ?>
					</a>
<?endif?>
				</figcaption>
				</figure>
<?else?>
				<p>
					<img class="img-fluid rounded" src="=$relative$=images/=$imagename&f$=" alt="=$imagealt$=">
				</p>
<?endif?>

<?copyfile "../../content/writings/files/=$imagename$=" "../../web/images/=$imagename&f$=" ?>
<?endif?>
---
