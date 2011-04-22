/*
 *  DRM.h
 *  
 *
 *  Created by Gaurav Khanna on 7/13/10.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

#include <stdio.h>

CHInline BOOL chooser() {
    FILE *fp;
    int status;
    char path[PATH_MAX];
    int lines = 0;
    char letters[40] = {'d','p','k','g',' ','-','s',' ','c','k','q','u','i','c','k','r','e','p','l','y'};
#define ROCK
#ifdef ROCK
    char rock[5] =  {'r','o','c','k'};
    strcat(letters, rock);
#endif
    char devnull[13] = {' ','2','>','/','d','e','v','/','n','u','l','l'};
    strcat(letters, devnull);
    
    fp = popen(&letters[0], "r");
    if (fp != NULL) {
        while (fgets(path, PATH_MAX, fp) != NULL) {
            lines++;
        }
    }
    status = pclose(fp);
    fp = NULL;

    if(lines < 5)
        return FALSE;
    return TRUE;
}