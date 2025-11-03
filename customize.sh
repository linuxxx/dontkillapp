##########################################################################################
#
# Magisk Module Installer Script
#
##########################################################################################

# skip all default installation steps
SKIPUNZIP=0

# Set what you want to display when installing your module

print_modname() {
  ui_print " "
  ui_print "*******************************"
  ui_print " dont kill my app"
  ui_print "*******************************"
  ui_print " "
}


# You can add more functions to assist your custom script code
print_modname
