#!/bin/bash

#### Copy paste with sed 1.0
#### Needs to be less of an hack, look into escaping new lines
#### so that reading file is not necessary. 




###### file content ######

file="$1"
filecontent=$(<$file)

###### string replaced ######
read -r -d '' text_replaced << EOF
    critical_options = [
        ("shutdown", _("Shut down immediately")),
        ("hibernate", _("Hibernate")),
        ("nothing", _("Do nothing"))
    ]
EOF

#


###### string inserted ######
read -r -d '' text_insterted << EOF
    critical_options = [
        ("shutdown", _("Shut down immediately")),
        ("hibernate", _("Hibernate")),
        ("suspend", _("Suspend")),
        ("nothing", _("Do nothing"))
    ]
EOF


###### escape and workaround for newline ######
text_insterted="$(echo "${text_insterted}" | sed -e 's/[\/&]/\\&/g' )"
text_replaced="$(echo "${text_replaced}" | sed -e 's/[]\/$*.^[]/\\&/g' )"
# newline hack, hide them in \f
text_insterted=`echo "${text_insterted}" | tr '\n' '\f' `
text_replaced=`echo "${text_replaced}" | tr '\n' '\f' `
filecontent=`echo "${filecontent}" | tr '\n' '\f' `


###### Replace ######
echo "$filecontent" | sed  "s/$text_replaced/$text_insterted/g"  | tr '\f' '\n'

