//
//  Shader.fsh
//  VCache
//
//  Created by Pavlo Gryb on 10/4/12.
//  Copyright (c) 2012 Pavlo Gryb. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
