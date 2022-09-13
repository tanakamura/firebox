#include <stdio.h>
#include <vector>
#include <string>
#include <string.h>

struct dev {
    std::string evdev_name;
};

enum dev_type {
    DEV_KBD,
    DEV_MOUSE,
    DEV_UNKNOWN
};

int main()
{
    FILE *in = fopen("/proc/bus/input/devices", "rb");
    if (in == nullptr) {
        perror("/proc/bus/input/devices");
        return 1;
    }

    std::vector<dev> mice;
    std::vector<dev> kbds;

    char buf[2048];
    std::string cur_name;

    while (1) {
        char *p = fgets(buf, 2048, in);
        if (p == nullptr) {
            break;
        }

        switch (p[0]) {
        case 'N':
            cur_name = p+3;
            break;

        case 'H': {
            char *start = p+3+9;
            char *cur = p+3+9;

            enum dev_type dt = DEV_UNKNOWN;
            std::string ev_name;
            puts(start);

            while (1) {
                if (*cur == ' ' || *cur == '\0') {
                    size_t len = cur-start;

                    if (len == 3 && (strncmp(start, "kbd", 3)==0)) {
                        dt = DEV_KBD;
                    } else if (len > 5 &&(strncmp(start, "mouse", 5)==0)) {
                        dt = DEV_MOUSE;
                    } else if (len > 5 &&(strncmp(start, "event", 5)==0)) {
                        ev_name = std::string(start, start+len-1);
                    }

                    if (*cur == '\0') {
                        break;
                    }

                    start = cur+1;
                }
                cur++;
            }

            switch (dt) {
            case DEV_KBD:
                kbds.emplace_back( dev{ev_name} );
                break;

            case DEV_MOUSE:
                mice.emplace_back( dev{ev_name} );
                break;
            }
        }
            break;
        }
    }

    fclose(in);

    puts(
        "Section \"ServerLayout\""
        "	Identifier     \"layout\""
        "	Screen      0  \"Screen0\" 0 0");

    for (size_t i=0; i<mice.size(); i++) {
        if (i == 0){
            printf("	InputDevice    \"Mouse0\" \"CorePointer\"\n");
        } else {
            printf("	InputDevice    \"Mouse%d\"\n", i);
        }
    }

    for (size_t i=0; i<mice.size(); i++) {
        if (i == 0){
            printf("	InputDevice    \"Keyboard0\" \"CoreKeyboard\"\n");
        } else {
            printf("	InputDevice    \"Keyboard%d\"\n", i);
        }
    }
    puts("EndSection");

    
);

}

